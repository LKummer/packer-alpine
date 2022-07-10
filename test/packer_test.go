package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/packer"
)

func TestPackerAlpineBuild(t *testing.T) {
	packerOptions := &packer.Options{
		Template:   "alpine.pkr.hcl",
		WorkingDir: "..",
		VarFiles:   []string{"secrets.pkr.hcl"},
		Vars: map[string]string{
			"template_name_suffix": "-test",
		},
	}

	packer.BuildArtifact(t, packerOptions)
}
