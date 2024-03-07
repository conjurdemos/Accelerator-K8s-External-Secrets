package e2e

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/klient"
	"sigs.k8s.io/e2e-framework/klient/decoder"
	"sigs.k8s.io/e2e-framework/klient/k8s"
)

func ExternalSecretWaitCondition(ctx context.Context, c klient.Client, es *v1beta1.ExternalSecret) func(ctx context.Context) (done bool, err error) {
	return func(ctx context.Context) (done bool, err error) {
		c.Resources(es.Namespace).Get(ctx, es.Name, es.Namespace, es)
		for _, status := range es.Status.Conditions {
			if status.Type == "Ready" && status.Status == "True" {
				return true, nil
			} else if status.Type == "Deleted" && status.Status == "True" {
				return false, fmt.Errorf("ExternalSecret %s has been deleted", es.Name)
			}
		}
		return false, nil
	}
}

func NewExternalSecret(name, namespace, secretStore, target string, variableMap map[string]string) v1beta1.ExternalSecret {
	es := v1beta1.ExternalSecret{
		ObjectMeta: metav1.ObjectMeta{
			Name:      name,
			Namespace: namespace,
		},
		Spec: v1beta1.ExternalSecretSpec{
			RefreshInterval: &metav1.Duration{
				Duration: time.Duration(10) * time.Second,
			},
			SecretStoreRef: v1beta1.SecretStoreRef{
				Kind: "SecretStore",
				Name: secretStore,
			},
			Target: v1beta1.ExternalSecretTarget{
				Name:           target,
				CreationPolicy: "Owner",
			},
		},
	}

	data := []v1beta1.ExternalSecretData{}
	for k, v := range variableMap {
		data = append(data, v1beta1.ExternalSecretData{
			SecretKey: k,
			RemoteRef: v1beta1.ExternalSecretDataRemoteRef{
				Key: v,
			},
		})
	}

	es.Spec.Data = data

	return es
}

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
