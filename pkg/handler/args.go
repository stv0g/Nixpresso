// SPDX-FileCopyrightText: 2025 Steffen Vogel <post@steffenvogel.de>
// SPDX-License-Identifier: Apache-2.0

package handler

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"

	"github.com/stv0g/nixpresso/pkg/nix"
	"github.com/stv0g/nixpresso/pkg/options"
	"github.com/stv0g/nixpresso/pkg/util"
)

type Arguments struct {
	// Request
	Proto      *string          `json:"proto,omitempty"`
	Method     *string          `json:"method,omitempty"`
	RequestURI *string          `json:"uri,omitempty"`
	Header     *http.Header     `json:"headers,omitempty"`
	Host       *string          `json:"host,omitempty"`
	Path       *string          `json:"path,omitempty"`
	Query      *url.Values      `json:"query,omitempty"`
	RemoteAddr *string          `json:"remoteAddr,omitempty"`
	BodyHash   *string          `json:"bodyHash,omitempty"`
	Body       *string          `json:"body,omitempty"`
	TLS        *ConnectionState `json:"tls,omitempty"`

	// Environment
	Options  *options.Options `json:"options,omitempty"`
	BasePath *string          `json:"basePath,omitempty"`

	// Error handling
	Error  *Error      `json:"error"`
	Result *EvalResult `json:"result,omitempty"`
}

func (h *Handler) ArgumentsFromRequest(req *http.Request) (args Arguments, err error) {
	if _, ok := h.InspectResult.ExpectedArgs["proto"]; ok {
		args.Proto = &req.Proto
	}

	if _, ok := h.InspectResult.ExpectedArgs["method"]; ok {
		args.Method = &req.Method
	}

	if _, ok := h.InspectResult.ExpectedArgs["uri"]; ok {
		args.RequestURI = &req.RequestURI
	}

	if _, ok := h.InspectResult.ExpectedArgs["headers"]; ok {
		args.Header = &req.Header
	}

	if _, ok := h.InspectResult.ExpectedArgs["query"]; ok {
		q := req.URL.Query()
		args.Query = &q
	}

	if _, ok := h.InspectResult.ExpectedArgs["path"]; ok {
		path := strings.TrimPrefix(req.URL.Path, h.opts.BasePath)
		args.Path = &path
	}

	if _, ok := h.InspectResult.ExpectedArgs["host"]; ok {
		args.Host = &req.Host
	}

	if _, ok := h.InspectResult.ExpectedArgs["remoteAddr"]; ok {
		args.RemoteAddr = &req.RemoteAddr
	}

	if _, ok := h.InspectResult.ExpectedArgs["tls"]; ok {
		args.TLS = convertConnectionState(req.TLS)
	}

	if _, ok := h.InspectResult.ExpectedArgs["bodyHash"]; ok {
		hash, path, err := nix.AddToStore(req.Context(), req.Body, "body")
		if err != nil {
			return args, fmt.Errorf("failed to add body to store: %w", err)
		}

		args.BodyHash = &hash
		args.Body = &path
	}

	if _, ok := h.InspectResult.ExpectedArgs["options"]; ok {
		args.Options = &h.opts
	}

	if _, ok := h.InspectResult.ExpectedArgs["basePath"]; ok {
		args.BasePath = &h.opts.BasePath
	}

	return args, nil
}

func (a *Arguments) Request() (req *http.Request, err error) {
	var body io.ReadCloser

	if a.Body != nil {
		if body, err = os.OpenFile(*a.Body, os.O_RDONLY, 0); err != nil {
			return nil, err
		}
	}

	req = httptest.NewRequest(
		util.Zero(a.Method),
		util.Zero(a.RequestURI),
		body)

	if a.Header != nil {
		req.Header = *a.Header
	}

	return req, nil
}

type ConnectionState struct {
	Version            string           `json:"version"`
	HandshakeComplete  bool             `json:"handshakeComplete"`
	DidResume          bool             `json:"didResume"`
	CipherSuite        string           `json:"cipherSuite"`
	NegotiatedProtocol string           `json:"negotiatedProtocol"`
	ServerName         string           `json:"serverName"`
	PeerCertificates   []*Certificate   `json:"peerCertificates"`
	VerifiedChains     [][]*Certificate `json:"verifiedChains"`
}

type Certificate struct {
	SerialNumber                string   `json:"serialNumber"`
	Issuer                      string   `json:"issuer"`
	Subject                     string   `json:"subject"`
	NotBefore                   int64    `json:"notBefore"`
	NotAfter                    int64    `json:"notAfter"`
	KeyUsage                    string   `json:"keyUsage"`
	ExtKeyUsage                 []string `json:"extKeyUsage"`
	SignatureAlgorithm          string   `json:"signatureAlgorithm"`
	PublicKeyAlgorithm          string   `json:"publicKeyAlgorithm"`
	Version                     int      `json:"version"`
	OCSPServer                  []string `json:"ocspServer"`
	IssuingCertificateURL       []string `json:"issuingCertificateURL"`
	DNSNames                    []string `json:"dnsNames"`
	EmailAddresses              []string `json:"emailAddresses"`
	IPAddresses                 []string `json:"ipAddresses"`
	URIs                        []string `json:"uris"`
	PermittedDNSDomainsCritical bool     `json:"permittedDNSDomainsCritical"`
	PermittedDNSDomains         []string `json:"permittedDNSDomains"`
	ExcludedDNSDomains          []string `json:"excludedDNSDomains"`
	PermittedIPRanges           []string `json:"permittedIPRanges"`
	ExcludedIPRanges            []string `json:"excludedIPRanges"`
	PermittedEmailAddresses     []string `json:"permittedEmailAddresses"`
	ExcludedEmailAddresses      []string `json:"excludedEmailAddresses"`
	PermittedURIDomains         []string `json:"permittedURIDomains"`
	ExcludedURIDomains          []string `json:"excludedURIDomains"`
}

func convertConnectionState(cs *tls.ConnectionState) *ConnectionState {
	if cs == nil {
		return nil
	}

	return &ConnectionState{
		Version:            tls.VersionName(cs.Version),
		HandshakeComplete:  cs.HandshakeComplete,
		DidResume:          cs.DidResume,
		CipherSuite:        tls.CipherSuiteName(cs.CipherSuite),
		NegotiatedProtocol: cs.NegotiatedProtocol,
		ServerName:         cs.ServerName,
		PeerCertificates:   convertCertificates(cs.PeerCertificates),
		VerifiedChains:     convertVerifiedChains(cs.VerifiedChains),
	}
}

func convertCertificate(cert *x509.Certificate) *Certificate {
	return &Certificate{
		SerialNumber:                cert.SerialNumber.String(),
		Issuer:                      cert.Issuer.String(),
		Subject:                     cert.Subject.String(),
		NotBefore:                   cert.NotBefore.Unix(),
		NotAfter:                    cert.NotAfter.Unix(),
		KeyUsage:                    keyUsageToString(cert.KeyUsage),
		ExtKeyUsage:                 extKeyUsageToString(cert.ExtKeyUsage),
		SignatureAlgorithm:          cert.SignatureAlgorithm.String(),
		PublicKeyAlgorithm:          cert.PublicKeyAlgorithm.String(),
		Version:                     cert.Version,
		OCSPServer:                  cert.OCSPServer,
		IssuingCertificateURL:       cert.IssuingCertificateURL,
		DNSNames:                    cert.DNSNames,
		EmailAddresses:              cert.EmailAddresses,
		IPAddresses:                 convertIPAddresses(cert.IPAddresses),
		URIs:                        convertURIs(cert.URIs),
		PermittedDNSDomainsCritical: cert.PermittedDNSDomainsCritical,
		PermittedDNSDomains:         cert.PermittedDNSDomains,
		ExcludedDNSDomains:          cert.ExcludedDNSDomains,
		PermittedIPRanges:           convertIPRanges(cert.PermittedIPRanges),
		ExcludedIPRanges:            convertIPRanges(cert.ExcludedIPRanges),
		PermittedEmailAddresses:     cert.PermittedEmailAddresses,
		ExcludedEmailAddresses:      cert.ExcludedEmailAddresses,
		PermittedURIDomains:         cert.PermittedURIDomains,
		ExcludedURIDomains:          cert.ExcludedURIDomains,
	}
}

func convertIPAddresses(ips []net.IP) []string {
	var result []string
	for _, ip := range ips {
		result = append(result, ip.String())
	}
	return result
}

func convertURIs(uris []*url.URL) []string {
	var result []string
	for _, uri := range uris {
		result = append(result, uri.String())
	}
	return result
}

func convertIPRanges(ranges []*net.IPNet) []string {
	var result []string
	for _, r := range ranges {
		result = append(result, r.String())
	}
	return result
}

func keyUsageToString(usage x509.KeyUsage) string {
	var usages []string

	if usage&x509.KeyUsageDigitalSignature != 0 {
		usages = append(usages, "digitalSignature")
	}

	if usage&x509.KeyUsageContentCommitment != 0 {
		usages = append(usages, "contentCommitment")
	}

	if usage&x509.KeyUsageKeyEncipherment != 0 {
		usages = append(usages, "keyEncipherment")
	}

	if usage&x509.KeyUsageDataEncipherment != 0 {
		usages = append(usages, "dataEncipherment")
	}

	if usage&x509.KeyUsageKeyAgreement != 0 {
		usages = append(usages, "keyAgreement")
	}

	if usage&x509.KeyUsageCertSign != 0 {
		usages = append(usages, "certSign")
	}

	if usage&x509.KeyUsageCRLSign != 0 {
		usages = append(usages, "crlSign")
	}

	if usage&x509.KeyUsageEncipherOnly != 0 {
		usages = append(usages, "encipherOnly")
	}

	if usage&x509.KeyUsageDecipherOnly != 0 {
		usages = append(usages, "decipherOnly")
	}

	return strings.Join(usages, ", ")
}

func extKeyUsageToString(extUsages []x509.ExtKeyUsage) []string {
	var usages []string
	for _, usage := range extUsages {
		switch usage {
		case x509.ExtKeyUsageAny:
			usages = append(usages, "any")

		case x509.ExtKeyUsageServerAuth:
			usages = append(usages, "serverAuth")

		case x509.ExtKeyUsageClientAuth:
			usages = append(usages, "clientAuth")

		case x509.ExtKeyUsageCodeSigning:
			usages = append(usages, "codeSigning")

		case x509.ExtKeyUsageEmailProtection:
			usages = append(usages, "emailProtection")

		case x509.ExtKeyUsageIPSECEndSystem:
			usages = append(usages, "ipsecEndSystem")

		case x509.ExtKeyUsageIPSECTunnel:
			usages = append(usages, "ipsecTunnel")

		case x509.ExtKeyUsageIPSECUser:
			usages = append(usages, "ipsecUser")

		case x509.ExtKeyUsageTimeStamping:
			usages = append(usages, "timeStamping")

		case x509.ExtKeyUsageOCSPSigning:
			usages = append(usages, "ocspSigning")

		case x509.ExtKeyUsageMicrosoftServerGatedCrypto:
			usages = append(usages, "microsoftServerGatedCrypto")

		case x509.ExtKeyUsageNetscapeServerGatedCrypto:
			usages = append(usages, "netscapeServerGatedCrypto")
		}
	}
	return usages
}

func convertCertificates(certs []*x509.Certificate) []*Certificate {
	var result []*Certificate

	for _, cert := range certs {
		result = append(result, convertCertificate(cert))
	}

	return result
}

func convertVerifiedChains(chains [][]*x509.Certificate) [][]*Certificate {
	var result [][]*Certificate

	for _, chain := range chains {
		var certChain []*Certificate
		for _, cert := range chain {
			certChain = append(certChain, convertCertificate(cert))
		}
		result = append(result, certChain)
	}

	return result
}
