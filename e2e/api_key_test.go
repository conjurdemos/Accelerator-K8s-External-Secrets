package e2e

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1"
	"github.com/stretchr/testify/assert"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

func TestApiKey(t *testing.T) {
	f := features.New("Conjur & ESO integration using API key authentication").
		Setup(func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
			// Setup run before each Assessment

			// Add External Secrets objects to K8s client scheme
			err := v1beta1.AddToScheme(c.Client().Resources().GetScheme())
			assert.NoError(t, err)

			// Create API key based SecretStore
			var secretStore v1beta1.SecretStore
			err = Reload(ctx, c.Client(), fmt.Sprintf("%s.api-key-provider.yml", TestNamespace), &secretStore)
			assert.NoError(t, err)

			// Create ExternalSecret
			externalSecret := v1beta1.ExternalSecret{
				ObjectMeta: metav1.ObjectMeta{
					Name:      "test-external-secret",
					Namespace: TestNamespace,
				},
				Spec: v1beta1.ExternalSecretSpec{
					RefreshInterval: &metav1.Duration{
						Duration: time.Duration(10) * time.Second,
					},
					SecretStoreRef: v1beta1.SecretStoreRef{
						Kind: "SecretStore",
						Name: secretStore.Name,
					},
					Target: v1beta1.ExternalSecretTarget{
						Name:           "target-secret",
						CreationPolicy: "Owner",
					},
					Data: []v1beta1.ExternalSecretData{
						{
							SecretKey: "secret-key",
							RemoteRef: v1beta1.ExternalSecretDataRemoteRef{
								Key: "secrets/test_secret",
							},
						},
					},
				},
			}
			err = c.Client().Resources(TestNamespace).Create(ctx, &externalSecret)
			assert.NoError(t, err)

			// Wait for ExternalSecret status Ready
			ready := func(ctx context.Context) (done bool, err error) {
				c.Client().Resources(TestNamespace).Get(ctx, externalSecret.Name, externalSecret.Namespace, &externalSecret)
				for _, status := range externalSecret.Status.Conditions {
					if status.Type == "Ready" && status.Status == "True" {
						return true, nil
					} else if status.Type == "Deleted" && status.Status == "True" {
						return false, fmt.Errorf("ExternalSecret %s has been deleted", externalSecret.Name)
					}
				}
				return false, nil
			}
			err = wait.For(
				ready,
				wait.WithContext(ctx),
				wait.WithInterval(time.Duration(5)*time.Second),
				wait.WithTimeout(time.Duration(30)*time.Second),
			)
			assert.NoError(t, err)

			return ctx
		}).
		Assess("Secret set correctly in app Pod", func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
			// Check content of created Secret
			var targetSecret corev1.Secret
			err := c.Client().Resources(TestNamespace).Get(ctx, "target-secret", TestNamespace, &targetSecret)
			assert.NoError(t, err)
			assert.Equal(t, []byte("MyS3cretContent!"), targetSecret.Data["secret-key"])

			return ctx
		})

	Env.Test(t, f.Feature())
}