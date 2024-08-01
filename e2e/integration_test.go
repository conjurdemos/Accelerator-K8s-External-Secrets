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

func TestIntegration(t *testing.T) {
	testCases := []struct {
		name                string
		provider            string
		expectedSecretKey   string
		expectedSecretValue string
		externalSecret      v1beta1.ExternalSecret
	}{
		{
			name:                "Conjur & ESO integration using API key authentication",
			provider:            "api-key",
			expectedSecretKey:   "secret-key",
			expectedSecretValue: "MyS3cretContent!",
			externalSecret: NewExternalSecret(
				"external-secret-api-key",
				TestNamespace,
				"target-secret-api-key",
				map[string]string{
					"secret-key": "secrets/test_secret",
				},
			),
		},
		{
			name:                "Conjur & ESO integration using JWT authentication",
			provider:            "jwt",
			expectedSecretKey:   "secret-key",
			expectedSecretValue: "MyS3cretContent!",
			externalSecret: NewExternalSecret(
				"external-secret-jwt",
				TestNamespace,
				"target-secret-jwt",
				map[string]string{
					"secret-key": "secrets/test_secret",
				},
			),
		},
		{
			name:                "FindByName using API key authentication",
			provider:            "api-key",
			expectedSecretKey:   "secrets_test_secret", // Name of Conjur secret, with / replaced by _
			expectedSecretValue: "MyS3cretContent!",
			externalSecret: NewExternalSecretWithSearch(
				"external-secret-api-key",
				TestNamespace,
				"target-secret-api-key",
				"^.*test_secret$", // regex to match the secret
			),
		},
		{
			name:                "FindByTag using API key authentication",
			provider:            "api-key",
			expectedSecretKey:   "secrets_test_secret", // Name of Conjur secret, with / replaced by _
			expectedSecretValue: "MyS3cretContent!",
			externalSecret: NewExternalSecretsWithTags(
				"external-secret-api-key",
				TestNamespace,
				"target-secret-api-key",
				map[string]string{
					"conjur/kind": "demo",
				},
			),
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			var secretStore v1beta1.SecretStore

			f := features.New(tc.name).
				Setup(func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
					// Create provider based SecretStore
					err := Reload(ctx, c.Client(), fmt.Sprintf("%s.%s-provider.yml", TestNamespace, tc.provider), &secretStore)
					assert.NoError(t, err)
					// Assign the external secret to the secret store
					tc.externalSecret.Spec.SecretStoreRef = v1beta1.SecretStoreRef{
						Kind: "SecretStore",
						Name: secretStore.Name,
					}
					err = c.Client().Resources(TestNamespace).Create(ctx, &tc.externalSecret)
					assert.NoError(t, err)
					// Wait for ExternalSecret status Ready
					err = wait.For(
						ExternalSecretWaitCondition(ctx, c.Client(), &tc.externalSecret),
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
					err := c.Client().Resources(TestNamespace).Get(ctx, "target-secret-"+tc.provider, TestNamespace, &targetSecret)
					assert.NoError(t, err)
					assert.Equal(t, []byte(tc.expectedSecretValue), targetSecret.Data[tc.expectedSecretKey])
					return ctx
				}).
				Teardown(func(ctx context.Context, t *testing.T, c *envconf.Config) context.Context {
					// Delete ExternalSecret
					err := c.Client().Resources(TestNamespace).Delete(ctx, &tc.externalSecret)
					assert.NoError(t, err)
					return ctx
				})

			Env.Test(t, f.Feature())
		})
	}
}
