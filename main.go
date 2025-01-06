package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

var (
	addr           = flag.String("listen", ":8080", "Listen address")
	readTimeout    = flag.Duration("read-timeout", 10*time.Second, "Maximum duration for reading the entire request, including the body. A zero or negative value means there will be no timeout")
	writeTimeout   = flag.Duration("write-timeout", 10*time.Second, "Maximum duration before timing out writes of the response. It is reset whenever a new request's header is read")
	maxHeaderBytes = flag.Int("max-header-bytes", 1<<20, "Maximum number of bytes the server will read parsing the request header's keys and values, including the request line.")
	maxBodyBytes   = flag.Int("max-body-bytes", 512<<20, "")
	sandbox        = flag.String("sandbox", "true", "")
)

func main() {
	var filename string

	flag.Parse()

	if args := flag.Args(); len(args) < 1 {
		fmt.Printf("Usage: %s [OPTIONS] handler-file\n\n", os.Args[0])
		flag.Usage()
		os.Exit(1)
	} else {
		filename = flag.Arg(0)
	}

	nixOpts := map[string]string{
		"sandbox": *sandbox,
	}

	h, err := NewHandler(filename, nixOpts)
	if err != nil {
		log.Fatal(err)
	}

	s := &http.Server{
		Addr:           *addr,
		Handler:        h,
		ReadTimeout:    *readTimeout,
		WriteTimeout:   *writeTimeout,
		MaxHeaderBytes: *maxHeaderBytes,
	}

	log.Printf("Start listening on %s", *addr)

	log.Fatal(s.ListenAndServe())
}
