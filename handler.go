package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const NixStorePath = "/nix/store"

type EvalResult struct {
	Status  int
	Stream  bool
	Path    bool
	Sandbox bool
	Headers map[string][]string
	Body    string
}

type InspectResult struct {
	BodyRequired bool
}

type Handler struct {
	Filename     string
	BodyRequired bool
	NixOpts      map[string]string
}

func NewHandler(filename string, nixOpts map[string]string) (*Handler, error) {
	absFilename, err := filepath.Abs(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to determine absolute path: %w", err)
	}

	h := &Handler{
		Filename: absFilename,
		NixOpts:  nixOpts,
	}

	result := &InspectResult{}

	args := map[string]any{
		"handlerFile": h.Filename,
	}

	if err := runNixEval("api.nix", "inspect", args, h.NixOpts, result); err != nil {
		return nil, fmt.Errorf("failed to inspect handler: %w", err)
	}

	h.BodyRequired = result.BodyRequired

	log.Printf("Successfully inspected handler: %s (bodyRequired=%v)", h.Filename, h.BodyRequired)

	return h, nil
}

func (h *Handler) ServeHTTP(wr http.ResponseWriter, r *http.Request) {
	args := map[string]any{
		"handlerFile": h.Filename,
		"headers":     r.Header,
		"uri":         r.RequestURI,
		"query":       r.URL.Query(),
		"path":        r.URL.Path,
		"method":      r.Method,
		"proto":       r.Proto,
		"host":        r.Host,
		"remote":      r.RemoteAddr,
	}

	if h.BodyRequired {
		b, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(wr, fmt.Sprintf("Failed to read request body: %s", err), http.StatusInternalServerError)
			return
		}

		args["body"] = string(b)
	}

	result := &EvalResult{}
	if err := runNixEval("api.nix", "eval", args, h.NixOpts, result); err != nil {
		http.Error(wr, fmt.Sprintf("Evaluation failed: %s", err), http.StatusInternalServerError)
		return
	}

	log.Printf("Evaluation results: %+#v", result)

	if result.Stream {
		http.Error(wr, "Streaming not yet supported", http.StatusNotImplemented)
		return
	} else if result.Body != "" {
		if result.Path {
			if !strings.HasPrefix(result.Body, NixStorePath) {
				http.Error(wr, fmt.Sprintf("Path '%s' must be located beneath '%s'", result.Body, NixStorePath), http.StatusForbidden)
				return
			}

			f, err := os.Open(result.Body)
			if err != nil {
				http.Error(wr, fmt.Sprintf("Failed to open result: %s", err), http.StatusInternalServerError)
				return
			}
			defer f.Close()

			if _, err := io.Copy(wr, f); err != nil {
				http.Error(wr, fmt.Sprintf("Failed to write response body: %s", err), http.StatusInternalServerError)
				return
			}
		} else {
			if _, err := wr.Write([]byte(result.Body)); err != nil {
				http.Error(wr, fmt.Sprintf("Failed to write response body: %s", err), http.StatusInternalServerError)
				return
			}
		}
	}

}

func runNixEval(file, attribute string, args map[string]any, opts map[string]string, result any) error {
	cmd := exec.Command("nix", "eval", "--json", "--show-trace", "--file", file, attribute)
	cmd.Stderr = os.Stderr

	for name, value := range opts {
		cmd.Args = append(cmd.Args, "--option", name, value)
	}

	for name, value := range args {
		switch value := value.(type) {
		case string:
			cmd.Args = append(cmd.Args, "--argstr", name, value)
		default:
			jsonValue, err := json.Marshal(value)
			if err != nil {
				return fmt.Errorf("failed to marshal: %w", err)
			}

			nixValue := "builtins.fromJSON ''" + string(jsonValue) + "''"

			cmd.Args = append(cmd.Args, "--arg", name, nixValue)
		}
	}

	log.Printf("Invoking %s", strings.Join(cmd.Args, " "))

	out, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to run Nix: %w", err)
	}

	if err := json.Unmarshal(out, result); err != nil {
		return fmt.Errorf("failed to unmarshal: %w", err)
	}

	return nil
}
