package discordinteractions

import (
	"context"
	"crypto/ed25519"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	compute "cloud.google.com/go/compute/apiv1"
	"cloud.google.com/go/compute/apiv1/computepb"
	"github.com/GoogleCloudPlatform/functions-framework-go/funcframework"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cockroachdb/errors"
)

func init() {
	functions.HTTP("InstanceController", func(w http.ResponseWriter, r *http.Request) {
		logger := log.New(funcframework.LogWriter(r.Context()), "", 0)
		if err := run(w, r, logger); err != nil {
			logger.Println("Error:", err)
		}
	})
}

type Interaction struct {
	Type int `json:"type"`
	Data struct {
		Options []struct {
			Name  string `json:"name"`
			Value string `json:"value"`
		} `json:"options"`
	} `json:"data"`
}

func run(w http.ResponseWriter, r *http.Request, logger *log.Logger) error {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		return errors.Wrap(err, "failed to read request body")
	}

	if err := verify(r, body); err != nil {
		return err
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	var interaction *Interaction
	if err := json.Unmarshal(body, &interaction); err != nil {
		return errors.Wrap(err, "failed to unmarshal interaction")
	}

	command := interaction.Data.Options[0].Value

	json.NewEncoder(w).Encode(map[string]any{
		"type": 4,
		"data": map[string]string{
			"content": fmt.Sprintf("Your request to %s the server has been received.", command),
		},
	})

	switch command {
	case "start":
		if err := start(r.Context()); err != nil {
			return errors.Wrap(err, "failed to start instance")
		}
	case "stop":
		if err := stop(r.Context()); err != nil {
			return errors.Wrap(err, "failed to stop instance")
		}
	default:
		logger.Println("Unknown command:", command)
	}

	return nil
}

func verify(r *http.Request, body []byte) error {
	publicKeyHex := os.Getenv("CLIENT_PUBLIC_KEY")
	signatureHex := r.Header.Get("X-Signature-Ed25519")
	timestamp := r.Header.Get("X-Signature-Timestamp")

	publicKey, err := hex.DecodeString(publicKeyHex)
	if err != nil {
		return errors.Wrap(err, "invalid public key")
	}

	signature, err := hex.DecodeString(signatureHex)
	if err != nil {
		return errors.Wrap(err, "invalid signature")
	}

	message := append([]byte(timestamp), body...)

	if !ed25519.Verify(publicKey, message, signature) {
		return errors.New("signature verification failed")
	}

	return nil
}

func start(ctx context.Context) error {
	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		return errors.Wrap(err, "failed to create instances client")
	}
	defer instancesClient.Close()

	req := &computepb.StartInstanceRequest{
		Project:  os.Getenv("PROJECT_ID"),
		Zone:     os.Getenv("ZONE"),
		Instance: os.Getenv("INSTANCE"),
	}

	if _, err := instancesClient.Start(ctx, req); err != nil {
		return errors.Wrap(err, "unable to start instance")
	}

	// if err = op.Wait(ctx); err != nil {
	// 	return errors.Wrap(err, "failed to wait for instance start operation")
	// }

	// response, err := json.Marshal(map[string]string{
	// 	"content": "The VM has started successfully.",
	// })
	// if err != nil {
	// 	return errors.Wrap(err, "failed to marshal response")
	// }

	// if _, err := http.Post(os.Getenv("WEBHOOK_URL"), "application/json", bytes.NewReader(response)); err != nil {
	// 	return errors.Wrap(err, "failed to send webhook notification")
	// }

	return nil
}

func stop(ctx context.Context) error {
	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		return errors.Wrap(err, "failed to create instances client")
	}
	defer instancesClient.Close()

	req := &computepb.StopInstanceRequest{
		Project:  os.Getenv("PROJECT_ID"),
		Zone:     os.Getenv("ZONE"),
		Instance: os.Getenv("INSTANCE"),
	}

	if _, err := instancesClient.Stop(ctx, req); err != nil {
		return errors.Wrap(err, "unable to stop instance")
	}

	// if err = op.Wait(ctx); err != nil {
	// 	return errors.Wrap(err, "failed to wait for instance start operation")
	// }

	// response, err := json.Marshal(map[string]string{
	// 	"content": "The VM has stop successfully.",
	// })
	// if err != nil {
	// 	return errors.Wrap(err, "failed to marshal response")
	// }

	// if _, err := http.Post(os.Getenv("WEBHOOK_URL"), "application/json", bytes.NewReader(response)); err != nil {
	// 	return errors.Wrap(err, "failed to send webhook notification")
	// }

	return nil
}
