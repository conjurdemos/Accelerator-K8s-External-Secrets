package e2e

import (
	"context"
	"fmt"
	"os"
	"strings"

	"sigs.k8s.io/e2e-framework/klient"
	"sigs.k8s.io/e2e-framework/klient/decoder"
	"sigs.k8s.io/e2e-framework/klient/k8s"
)

func Reload(ctx context.Context, c klient.Client, filename string, target k8s.Object) error {
	err := ParseManifest(filename, target)
	if err != nil {
		return err
	}

	err = c.Resources(target.GetNamespace()).Delete(ctx, target)
	if err != nil && !strings.Contains(err.Error(), fmt.Sprintf("%q not found", target.GetName())) {
		return fmt.Errorf(
			"failed to delete existing %s %s in namespace %s: %v",
			target.GetObjectKind().GroupVersionKind().Kind,
			target.GetName(),
			target.GetNamespace(),
			err,
		)
	}

	err = c.Resources(target.GetNamespace()).Create(ctx, target)
	if err != nil {
		return fmt.Errorf(
			"failed to create %s %s in namespace %s: %v",
			target.GetObjectKind().GroupVersionKind().Kind,
			target.GetName(),
			target.GetNamespace(),
			err,
		)
	}

	return nil
}

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
