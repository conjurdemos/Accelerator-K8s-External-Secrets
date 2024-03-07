package e2e

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1"
	"sigs.k8s.io/e2e-framework/klient/conf"
	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
)

var Env env.Environment
var TestNamespace = os.Getenv("APP_NAMESPACE_NAME")

func TestMain(m *testing.M) {
	kubeconfigPath := conf.ResolveKubeConfigFile()
	config := envconf.NewWithKubeConfig(kubeconfigPath)

	Env = env.NewWithConfig(config)

	Env.Setup(func(ctx context.Context, c *envconf.Config) (context.Context, error) {
		// Setup run once before any feature

		// Add External Secrets API objects to K8s client scheme
		err := v1beta1.AddToScheme(c.Client().Resources().GetScheme())
		if err != nil {
			return ctx, fmt.Errorf("failed to add External Secrets API objects to K8s client scheme: %v", err)
		}

		return ctx, nil
	})

	os.Exit(Env.Run(m))
}
