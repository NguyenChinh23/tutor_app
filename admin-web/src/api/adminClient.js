
import axios from "axios";

const adminClient = axios.create({
  baseURL: "http://localhost:3000/api",
});

adminClient.interceptors.request.use((config) => {
  const token = localStorage.getItem("adminToken");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default adminClient;
