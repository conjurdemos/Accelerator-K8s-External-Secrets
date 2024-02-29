package e2e

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1"
	"github.com/stretchr/testify/assert"
	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/e2e-framework/klient/wait"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/features"
)

func TestJWT(t *testing.T) {
	var (
		secretStore    v1beta1.SecretStore
		externalSecret v1beta1.ExternalSecret
	)

	f := features.New("Conjur & ESO integration using JWT authentication").
		Setup(func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
			// Create JWT based SecretStore
			err := Reload(ctx, c.Client(), fmt.Sprintf("%s.jwt-provider.yml", TestNamespace), &secretStore)
			assert.NoError(t, err)

			// Create ExternalSecret
			externalSecret = NewExternalSecret(
				"external-secret-jwt",
				TestNamespace,
				secretStore.Name,
				"target-secret-jwt",
				map[string]string{
					"secret-key": "secrets/test_secret",
				},
			)
			err = c.Client().Resources(TestNamespace).Create(ctx, &externalSecret)
			assert.NoError(t, err)

			// Wait for ExternalSecret status Ready
			err = wait.For(
				ExternalSecretWaitCondition(ctx, c.Client(), &externalSecret),
				wait.WithContext(ctx),
				wait.WithInterval(time.Duration(5)*time.Second),
				wait.WithTimeout(time.Duration(30)*time.Second),
			)
			assert.NoError(t, err)

			return ctx
		}).
		Assess("K8s Secret set correctly with Conjur Secret data", func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
			// Check content of created Secret
			var targetSecret corev1.Secret
			err := c.Client().Resources(TestNamespace).Get(ctx, "target-secret-jwt", TestNamespace, &targetSecret)
			assert.NoError(t, err)
			assert.Equal(t, []byte("MyS3cretContent!"), targetSecret.Data["secret-key"])

			return ctx
		}).
		Teardown(func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
			// Delete ExternalSecret
			err := c.Client().Resources(TestNamespace).Delete(ctx, &externalSecret)
			assert.NoError(t, err)

			return ctx
		})

	Env.Test(t, f.Feature())
}
