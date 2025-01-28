// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package cmd

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/stv0g/nixpresso/pkg"
	"github.com/stv0g/nixpresso/pkg/handler"
	"github.com/stv0g/nixpresso/pkg/nix"
	"github.com/stv0g/nixpresso/pkg/options"
	"github.com/stv0g/nixpresso/pkg/util"
)

var (
	rootCmd = &cobra.Command{
		Use:          "nixpresso [flags] <handler> -- [nix-flags] -- [run-flags]",
		Args:         cobra.RangeArgs(0, 1),
		ArgAliases:   []string{"attribute"},
		RunE:         run,
		Version:      pkg.Version,
		SilenceUsage: true,
	}

	addr            string
	tlsCertFilename string
	tlsKeyFilename  string
	maxReadTime     time.Duration
	maxWriteTime    time.Duration
	debug           bool
	inspect         bool
	test            string
	testOverwrite   bool

	opts options.Options
)

func init() {
	pf := rootCmd.PersistentFlags()

	pf.StringVarP(&addr, "listen", "L", ":8080", "listen address")
	pf.StringVar(&tlsCertFilename, "tls-cert", "", "TLS certificate file")
	pf.StringVar(&tlsKeyFilename, "tls-key", "", "TLS key file")
	pf.DurationVar(&maxReadTime, "max-read-time", 10*time.Minute, "maximum duration for reading the entire request, including the body. A zero or negative value means there will be no timeout")
	pf.DurationVar(&maxWriteTime, "max-write-time", 10*time.Minute, "maximum duration before timing out writes of the response. It is reset whenever a new request's header is read")
	pf.DurationVar(&opts.MaxRequestTime, "max-request-time", 20*time.Minute, "maximum duration for the entire request (evaluation, building and running). A zero or negative value means there will be no timeout")
	pf.DurationVar(&opts.MaxEvalTime, "max-eval-time", 5*time.Minute, "maximum duration for the evaluation phase. A zero or negative value means there will be no timeout")
	pf.DurationVar(&opts.MaxBuildTime, "max-build-time", 10*time.Minute, "maximum duration for the build phase. A zero or negative value means there will be no timeout")
	pf.DurationVar(&opts.MaxRunTime, "max-run-time", 10*time.Minute, "maximum duration for the run phase. A zero or negative value means there will be no timeout")
	pf.Int64Var(&opts.MaxRequestBytes, "max-request-bytes", 32<<20, "maximum number of bytes the server will read from the request body")
	pf.Int64Var(&opts.MaxResponseBytes, "max-response-bytes", 32<<20, "maximum number of bytes the server will serve in the response body")
	pf.BoolVarP(&opts.AllowStore, "allow-store", "s", true, "allow serving or executing content from Nix store")
	pf.VarP(&opts.AllowedModes, "allow-mode", "m", fmt.Sprintf("allowed response modes (default %s)", strings.Join(options.DefaultModes, ", ")))
	pf.VarP(&opts.AllowedTypes, "allow-type", "t", fmt.Sprintf("alowed response types (default %s)", strings.Join(options.AllTypes, ", ")))
	pf.VarP(&opts.AllowedPaths, "allow-path", "p", "allowed paths from which content can be served or executed")
	pf.StringVarP(&opts.BasePath, "base-path", "b", "", "initial base path to pass to the handler")
	pf.BoolVarP(&debug, "debug", "d", false, "enable debug logging")
	pf.BoolVarP(&opts.EvalCache, "eval-cache", "c", true, "enable evaluation caching")
	pf.BoolVarP(&inspect, "inspect", "i", false, "inspect handler and print result to standard output")
	pf.StringVarP(&test, "test", "T", "", "path to a file with test cases which should be executed")
	pf.BoolVar(&testOverwrite, "test-overwrite", false, "overwrite test results in test file")

	pf.IntVarP(&opts.Verbose, "verbose", "v", -1, "verbosity level")

	rootCmd.RegisterFlagCompletionFunc("allow-mode", cobra.FixedCompletions(options.AllModes, cobra.ShellCompDirectiveNoFileComp)) //nolint:errcheck
	rootCmd.RegisterFlagCompletionFunc("allow-type", cobra.FixedCompletions(options.AllTypes, cobra.ShellCompDirectiveNoFileComp)) //nolint:errcheck

	rootCmd.SetVersionTemplate(fmt.Sprintf("Nixpresso version {{.Version}}\nNix path %s\n", nix.Executable))
}

func Execute() {
	os.Args, opts.NixArgs = util.SplitSlice(os.Args, "--")
	opts.NixArgs, opts.RunArgs = util.SplitSlice(opts.NixArgs, "--")

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func run(cmd *cobra.Command, args []string) error {
	if len(args) > 0 {
		opts.Handler = args[0]
	}

	if debug && opts.Verbose < 0 {
		opts.Verbose = 5
	}

	if opts.AllowedModes == nil {
		opts.AllowedModes = options.DefaultModes
	}

	if opts.AllowedTypes == nil {
		opts.AllowedTypes = options.AllTypes
	}

	if opts.Verbose >= 5 {
		slog.SetLogLoggerLevel(slog.LevelDebug)

		slog.Debug("Nixpresso",
			slog.String("version", pkg.Version))
		slog.Debug("Nix",
			slog.String("path", nix.Executable))

		slog.Debug("Options:")
		util.DumpJSON(opts)
	}

	h, err := handler.NewHandler(opts)
	if err != nil {
		return fmt.Errorf("failed to create handler: %w", err)
	}

	switch {
	case inspect:
		util.DumpJSONf(os.Stdout, h.InspectResult)

	case test != "":
		if err := h.Test(test, testOverwrite); err != nil {
			return err
		}

	default:
		if err := h.ListenAndServe(addr, maxReadTime, maxWriteTime, tlsCertFilename, tlsKeyFilename); err != nil {
			return err
		}
	}

	return nil
}
