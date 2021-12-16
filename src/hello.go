package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	http.HandleFunc("/", HelloHandler)
	fmt.Println("Hello world!  Starting to listen...")
	http.ListenAndServe(":8080", nil)
}

func HelloHandler(res http.ResponseWriter, r *http.Request) {
	res.WriteHeader(http.StatusOK)
	res.Header().Set("Content-Type", "application/json")
	io.WriteString(res, `{"fancy-demo": true}`)
}
