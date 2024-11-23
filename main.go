package main

import (
	"io/ioutil"
	"log"
	"net/http"
	"os/exec"
)

func runBallerina(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request", http.StatusInternalServerError)
		return
	}

	tmpfile, err := ioutil.TempFile("", "ballerina-*.bal")
	if err != nil {
		http.Error(w, "Error creating temp file", http.StatusInternalServerError)
		return
	}
	defer tmpfile.Close()

	if _, err := tmpfile.Write(body); err != nil {
		http.Error(w, "Error writing to temp file", http.StatusInternalServerError)
		return
	}

	cmd := exec.Command("docker", "run", "--rm", "-v", tmpfile.Name()+":/usr/src/app/project.bal", "ballerina/ballerina:latest", "bal", "run", "/usr/src/app/project.bal")
	output, err := cmd.CombinedOutput()
	if err != nil {
		http.Error(w, "Error executing Ballerina code: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(output)
}

func main() {
	http.HandleFunc("/run", runBallerina)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
