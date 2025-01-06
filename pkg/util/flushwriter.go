// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package util

import (
	"bytes"
	"net/http"
)

type FlushMode int

const (
	FlushModeNone FlushMode = iota
	FlushModeLine
	FlushModeBytes
)

type FlushingResponseWriter struct {
	http.ResponseWriter
	http.Flusher

	Mode            FlushMode
	BytesFlushAfter int
	BytesWritten    int
}

func (fw *FlushingResponseWriter) Write(p []byte) (int, error) {
	n, err := fw.ResponseWriter.Write(p)

	if fw.Mode == FlushModeLine {
		if n := bytes.Count(p, []byte{'\n'}); n > 0 {
			fw.Flush()
		}
	} else if fw.Mode == FlushModeBytes {
		fw.BytesWritten += n
		if fw.BytesWritten >= fw.BytesFlushAfter {
			fw.Flush()
			fw.BytesWritten = 0
		}
	}

	return n, err
}
