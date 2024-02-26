package e2e

import (
	"fmt"
	"os"

	"sigs.k8s.io/e2e-framework/klient/decoder"
	"sigs.k8s.io/e2e-framework/klient/k8s"
)

func ParseManifest(filename string, target k8s.Object) error {
	filepath := fmt.Sprintf("../manifest/generated/%s", filename)
	file, err := os.Open(filepath)
	if err != nil {
		return fmt.Errorf("failed to open file %s: %v", filepath, err)
	}

	err = decoder.Decode(file, target)
	if err != nil {
		return fmt.Errorf("failed to decode content of file %s into K8s object: %v", filepath, err)
	}

	return nil
}
