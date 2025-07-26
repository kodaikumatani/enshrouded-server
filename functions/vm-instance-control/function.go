package function

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"

	compute "cloud.google.com/go/compute/apiv1"
	"cloud.google.com/go/compute/apiv1/computepb"
	"github.com/GoogleCloudPlatform/functions-framework-go/funcframework"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/cockroachdb/errors"
	"github.com/kodaikumatani/enshrouded/functions/vm-instance-control/googlecloud/pubsub"
)

func init() {
	functions.CloudEvent("VmInstanceControl", run)
}

func run(ctx context.Context, e event.Event) error {
	var msg pubsub.MessagePublishedData
	err := e.DataAs(&msg)
	if err != nil {
		return fmt.Errorf("event.DataAs: %w", err)
	}

	jsonHandler := slog.NewJSONHandler(
		funcframework.LogWriter(ctx),
		&slog.HandlerOptions{ReplaceAttr: replacer},
	)

	logger := slog.New(jsonHandler).
		With("messageId", msg.Message.MessageID).
		With("publishTime", msg.Message.PublishTime)

	var body []byte
	switch string(msg.Message.Data) {
	case "start":
		body, err = startInstance(ctx, logger)
		if err != nil {
			return errors.Wrap(err, "failed to start instance")
		}
	case "stop":
		body, err = stopInstance(ctx, logger)
		if err != nil {
			return errors.Wrap(err, "failed to stop instance")
		}
	default:
		return errors.New("unknown command")
	}

	url := os.Getenv("WEBHOOK_URL")
	resp, err := http.Post(url, "application/json", bytes.NewReader(body))
	if err != nil {
		return errors.Wrap(err, "failed to send webhook notification")
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	logger.Info(string(respBody))

	return nil
}

func startInstance(ctx context.Context, logger *slog.Logger) ([]byte, error) {
	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create instances client")
	}
	defer instancesClient.Close()

	req := &computepb.StartInstanceRequest{
		Project:  os.Getenv("PROJECT_ID"),
		Zone:     os.Getenv("ZONE"),
		Instance: os.Getenv("INSTANCE"),
	}

	logger.Info("Start starts an instance")

	op, err := instancesClient.Start(ctx, req)
	if err != nil {
		return nil, errors.Wrap(err, "unable to start instance")
	}

	if err = op.Wait(ctx); err != nil {
		return nil, errors.Wrap(err, "failed to wait for instance start operation")
	}

	logger.Info("vm start operation complete")

	return json.Marshal(map[string]string{
		"content": "The VM has started successfully.",
	})
}

func stopInstance(ctx context.Context, logger *slog.Logger) ([]byte, error) {
	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create instances client")
	}
	defer instancesClient.Close()

	req := &computepb.StopInstanceRequest{
		Project:  os.Getenv("PROJECT_ID"),
		Zone:     os.Getenv("ZONE"),
		Instance: os.Getenv("INSTANCE"),
	}

	logger.Info("Stop stops a running instance")

	op, err := instancesClient.Stop(ctx, req)
	if err != nil {
		return nil, errors.Wrap(err, "unable to stop instance")
	}

	if err = op.Wait(ctx); err != nil {
		return nil, errors.Wrap(err, "failed to wait for instance start operation")
	}

	logger.Info("vm stop operation complete")

	return json.Marshal(map[string]string{
		"content": "The VM has stopped successfully.",
	})
}

func replacer(groups []string, a slog.Attr) slog.Attr {
	// Rename attribute keys to match Cloud Logging structured log format
	switch a.Key {
	case slog.LevelKey:
		a.Key = "severity"
		// Map slog.Level string values to Cloud Logging LogSeverity
		// https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogSeverity
		if level := a.Value.Any().(slog.Level); level == slog.LevelWarn {
			a.Value = slog.StringValue("WARNING")
		}
	case slog.TimeKey:
		a.Key = "timestamp"
	case slog.MessageKey:
		a.Key = "message"
	}
	return a
}
