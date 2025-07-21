package function

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"

	compute "cloud.google.com/go/compute/apiv1"
	"cloud.google.com/go/compute/apiv1/computepb"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
	functions.HTTP("InstanceController", handleRequest)
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path
	if strings.HasSuffix(path, "/start") {
		start(w, r)
	} else if strings.HasSuffix(path, "/stop") {
		stop(w, r)
	} else {
		http.Error(w, "Invalid path. Use /start or /stop", http.StatusBadRequest)
	}
}

func start(w http.ResponseWriter, _ *http.Request) {
	ctx := context.Background()

	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		log.Printf("An internal error occurred: %v", err)
		http.Error(w, "An internal error occurred", http.StatusInternalServerError)
		return
	}
	defer instancesClient.Close()

	req := &computepb.StartInstanceRequest{
		Project:  os.Getenv("PROJECT_ID"),
		Zone:     os.Getenv("ZONE"),
		Instance: os.Getenv("INSTANCE"),
	}

	op, err := instancesClient.Start(ctx, req)
	if err != nil {
		log.Printf("unable to start instance: %v", err)
		http.Error(w, "unable to start instance", http.StatusInternalServerError)
		return
	}

	if err = op.Wait(ctx); err != nil {
		log.Printf("unable to wait for the operation to complete: %v", err)
		http.Error(w, "unable to wait for the operation to complete", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Instance started successfully.",
	})
}

func stop(w http.ResponseWriter, _ *http.Request) {
	ctx := context.Background()

	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		log.Printf("An internal error occurred: %v", err)
		http.Error(w, "An internal error occurred", http.StatusInternalServerError)
		return
	}
	defer instancesClient.Close()

	req := &computepb.StopInstanceRequest{
		Project:  os.Getenv("PROJECT_ID"),
		Zone:     os.Getenv("ZONE"),
		Instance: os.Getenv("INSTANCE"),
	}

	if _, err := instancesClient.Stop(ctx, req); err != nil {
		log.Printf("unable to stop instance: %v", err)
		http.Error(w, "unable to stop instance", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Instance stoped successfully.",
	})
}
