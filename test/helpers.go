package test

import (
	"bytes"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"net/http"
	"os"

	tgssh "github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"
	"golang.org/x/crypto/ssh"
)

func generateED25519KeyPair(t testing.TestingT) *tgssh.KeyPair {
	keyPair, err := generateED25519KeyPairE(t)
	if err != nil {
		t.Fatal(err)
	}
	return keyPair
}

// Terratest contains a utility to generate RSA key pairs. As of OpenSSH 8.8
// ssh-rsa is disabled by default and is considered weak.
// See https://www.openssh.com/txt/release-8.7
// It is inspired by the existing GenerateRSAKeyPair from Terratest.
// See https://github.com/gruntwork-io/terratest/blob/v0.40.12/modules/ssh/key_pair.go
func generateED25519KeyPairE(t testing.TestingT) (*tgssh.KeyPair, error) {
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return nil, err
	}

	keyPKCS8, err := x509.MarshalPKCS8PrivateKey(privateKey)
	if err != nil {
		return nil, err
	}

	keyPEMBlock := &pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: keyPKCS8,
	}
	keyPEM := string(pem.EncodeToMemory(keyPEMBlock))

	sshPubKey, err := ssh.NewPublicKey(publicKey)
	if err != nil {
		return nil, err
	}
	pubKeyString := string(ssh.MarshalAuthorizedKey(sshPubKey))
	return &tgssh.KeyPair{PublicKey: pubKeyString, PrivateKey: keyPEM}, nil
}

func deleteProxmoxVM(t testing.TestingT, name string) {
	id := findProxmoxVMID(t, name)
	deleteProxmoxVMID(t, id)
}

func deleteProxmoxVMID(t testing.TestingT, vmID string) {
	client := new(http.Client)
	client.Transport = &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}

	proxmoxURL := os.Getenv("PROXMOX_URL")
	username := os.Getenv("PROXMOX_USERNAME")
	token := os.Getenv("PROXMOX_TOKEN")
	authorization := fmt.Sprintf("PVEAPIToken=%s=%s", username, token)

	url := fmt.Sprintf("%s/nodes/bfte/qemu/%s", proxmoxURL, vmID)
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	assert.NoError(t, err)
	req.Header.Set("Authorization", authorization)
	res, err := client.Do(req)
	assert.NoError(t, err)
	assert.Equal(t, res.StatusCode, http.StatusOK)
}

func findProxmoxVMID(t testing.TestingT, name string) string {
	client := new(http.Client)
	client.Transport = &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}

	proxmoxURL := os.Getenv("PROXMOX_URL")
	username := os.Getenv("PROXMOX_USERNAME")
	token := os.Getenv("PROXMOX_TOKEN")
	authorization := fmt.Sprintf("PVEAPIToken=%s=%s", username, token)

	url := fmt.Sprintf("%s/nodes/bfte/qemu", proxmoxURL)
	req, err := http.NewRequest(http.MethodGet, url, nil)
	assert.NoError(t, err)
	req.Header.Set("Authorization", authorization)
	res, err := client.Do(req)
	assert.NoError(t, err)
	assert.Equal(t, res.StatusCode, http.StatusOK)

	buf := new(bytes.Buffer)
	_, err = buf.ReadFrom(res.Body)
	assert.NoError(t, err)
	machines := ProxmoxVMList{}
	err = json.Unmarshal(buf.Bytes(), &machines)
	assert.NoError(t, err)

	matchingMachines := []ProxmoxVM{}
	for _, machine := range machines.Data {
		if machine.Name == name {
			matchingMachines = append(matchingMachines, machine)
		}
	}

	// Avoid deleting VMs when more than 1 VM matches the name to reduce the blast radius
	// and avoid damaging resources because of naming conflicts.
	assert.Equal(t, 1, len(matchingMachines), fmt.Sprintf("Found more than 1 VM or template named %s. Please delete manually.", name))

	return matchingMachines[0].ID
}

type ProxmoxVM struct {
	ID   string `json:"vmid"`
	Name string `json:"name"`
}

type ProxmoxVMList struct {
	Data []ProxmoxVM `json:"data"`
}
