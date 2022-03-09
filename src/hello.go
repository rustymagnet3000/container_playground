package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func hello(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello!")
}
func date(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "time now: %s", time.Now().Format("15:04:05"))
}
func main() {
	http.HandleFunc("/", hello)
	http.HandleFunc("/date", date)
	port := os.Getenv("LISTENING_PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("listening on port:%s", port)
	err := http.ListenAndServe("localhost:"+port, nil)
	if err != nil {
		log.Fatalf("Failed to start server:%v", err)
	}
}
