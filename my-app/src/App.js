import React, { useState } from "react";
import axios from 'axios';

function App() {
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [result, setResult] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleFileChange = (e) => {
    const selected = e.target.files[0];
    setFile(selected);
    setResult("");
    setErrorMessage("");

    if (selected) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreview(reader.result);
      };
      reader.readAsDataURL(selected);
    } else {
      setPreview(null);
    }
  };

  // Use different URLs based on environment
  // When running in browser, use localhost:5002
  // When running in Docker, the nginx proxy will handle the routing
  const API_URL = window.location.hostname === 'localhost'
    ? "http://localhost:5002"
    : "/";  // Use relative URL for Docker environment

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!file) {
      setErrorMessage("Please select an image before uploading.");
      return;
    }

    const formData = new FormData();
    formData.append("image", file);

    try {
      setIsLoading(true);
      console.log("Sending request to:", `${API_URL}/predict`);

      // Using axios instead of fetch for the request
      const response = await axios.post(`${API_URL}/predict`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
        },
      });

      console.log("Response data:", response.data);
      setResult(response.data.prediction || "Unexpected response from server.");
    } catch (error) {
      console.error("Full error:", error);
      setErrorMessage(
        "❌ Unable to connect to the server. Please ensure the backend is running."
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.overlay}>
        <div style={styles.card}>
          <h1 style={styles.title}>🩺 Breast Cancer Detection</h1>

          <form onSubmit={handleSubmit} style={styles.form}>
            <input
              type="file"
              onChange={handleFileChange}
              accept="image/*"
              style={styles.fileInput}
            />

            {preview && (
              <img src={preview} alt="preview" style={styles.preview} />
            )}

            <button type="submit" style={styles.button} disabled={isLoading}>
              {isLoading ? "Analyzing..." : "Upload Image"}
            </button>
          </form>

          {isLoading && <div style={styles.spinner}></div>}

          {result && (
            <div
              style={{
                ...styles.resultBox,
                backgroundColor:
                  result === "Cancerous" ? "#ffe5e5" : "#e5ffe9",
                color: result === "Cancerous" ? "#c0392b" : "#27ae60",
              }}
            >
              {result === "Cancerous" ? "⚠" : "✅"} Result: {result}
            </div>
          )}

          {errorMessage && <p style={styles.error}>{errorMessage}</p>}
        </div>
      </div>
    </div>
  );
}

const styles = {
  container: {
    fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
    minHeight: "100vh",
    backgroundImage: "url('/background.jpg')",
    backgroundSize: "cover",
    backgroundPosition: "center",
    backgroundRepeat: "no-repeat",
  },
  overlay: {
    minHeight: "100vh",
    backdropFilter: "blur(4px)",
    backgroundColor: "rgba(255, 255, 255, 0.7)",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "20px",
  },
  card: {
    backgroundColor: "#fff",
    padding: "40px",
    borderRadius: "20px",
    boxShadow: "0 10px 30px rgba(0, 0, 0, 0.1)",
    maxWidth: "500px",
    width: "100%",
    textAlign: "center",
    transition: "all 0.3s ease-in-out",
  },
  title: {
    fontSize: "2rem",
    marginBottom: "25px",
    color: "#2c3e50",
  },
  form: {
    display: "flex",
    flexDirection: "column",
    gap: "20px",
    alignItems: "center",
  },
  fileInput: {
    padding: "10px",
    borderRadius: "8px",
    border: "1px solid #ccc",
    fontSize: "1rem",
    width: "100%",
  },
  button: {
    background: "linear-gradient(135deg, #3498db, #2980b9)",
    color: "#fff",
    padding: "12px 24px",
    border: "none",
    borderRadius: "10px",
    cursor: "pointer",
    fontSize: "1rem",
    fontWeight: "600",
    width: "100%",
    transition: "background 0.3s ease",
  },
  resultBox: {
    marginTop: "25px",
    padding: "15px 20px",
    borderRadius: "12px",
    fontSize: "1.2rem",
    fontWeight: "600",
    border: "2px solid #ddd",
  },
  error: {
    color: "#c0392b",
    marginTop: "15px",
    fontWeight: "500",
  },
  spinner: {
    marginTop: "15px",
    border: "6px solid #f3f3f3",
    borderTop: "6px solid #3498db",
    borderRadius: "50%",
    width: "40px",
    height: "40px",
    animation: "spin 1s linear infinite",
  },
  preview: {
    width: "100%",
    maxHeight: "200px",
    objectFit: "contain",
    borderRadius: "10px",
    marginTop: "10px",
    boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
  },
};

// Injecting CSS animation for spinner into the page
if (typeof document !== "undefined") {
  const styleSheet = document.styleSheets[0];
  if (styleSheet) {
    styleSheet.insertRule(`
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    `, styleSheet.cssRules.length);
  }
}

export default App;

