package test

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/gruntwork-io/terratest/modules/packer"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestPackerAlpineBuild(t *testing.T) {
	templateName := "packer-alpine-test-" + uuid.NewString()
	packerOptions := &packer.Options{
		Template:   "alpine.pkr.hcl",
		WorkingDir: "..",
		VarFiles:   []string{"secrets.pkr.hcl"},
		Vars: map[string]string{
			"template_name": templateName,
		},
	}

	defer deleteProxmoxVM(t, templateName)
	packer.BuildArtifact(t, packerOptions)
	// Proxmox takes a second to rename the template.
	time.Sleep(5 * time.Second)

	sshKeyPair := generateED25519KeyPair(t)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "terraform",
		Vars: map[string]interface{}{
			"cloud_init_public_keys": sshKeyPair.PublicKey,
			"proxmox_template":       templateName,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	sshIP := terraform.Output(t, terraformOptions, "ssh_ip")
	sshUser := terraform.Output(t, terraformOptions, "user")
	password := terraform.Output(t, terraformOptions, "password")
	host := ssh.Host{
		Hostname:    sshIP,
		SshUserName: sshUser,
		SshKeyPair:  sshKeyPair,
		CustomPort:  2222,
	}

	// Check Cloud Init ran successfully and SSH works.
	ssh.CheckSshCommand(t, host, "cloud-init status --wait")

	// Check SSH password authentication is disabled.
	err := ssh.CheckSshConnectionE(t, ssh.Host{
		Hostname:    sshIP,
		SshUserName: sshUser,
		Password:    password,
		CustomPort:  2222,
	})
	assert.Error(t, err)

	// Check root password is locked.
	rootPasswordStatus := ssh.CheckSshCommand(t, host, "sudo passwd --status root")
	assert.Regexp(t, "^root L ", rootPasswordStatus)

	// Check root shell history file is not present.
	ssh.CheckSshCommand(t, host, "!(sudo test -f /root/.ash_history)")

	// Check Python is installed.
	ssh.CheckSshCommand(t, host, "python3 --version")
	ssh.CheckSshCommand(t, host, "pip --version")

	// Check sudo is installed.
	ssh.CheckSshCommand(t, host, "sudo --version")
}
