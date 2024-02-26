package e2e

import (
	"os"
	"testing"

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
	os.Exit(Env.Run(m))
}
