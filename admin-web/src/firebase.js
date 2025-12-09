// src/firebase.js
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

// ⚙️ Cấu hình Firebase
const firebaseConfig = {
  apiKey: "AIzaSyA2IEvhB7IMx0m5s6yG1NUPVoilJ8Rodxw",
  authDomain: "tutorapp-36170.firebaseapp.com",
  projectId: "tutorapp-36170",
  storageBucket: "tutorapp-36170.appspot.com",
  messagingSenderId: "785080321235",
  appId: "1:785080321235:web:f18510aaa6962a31528026",
  measurementId: "G-3BBKLFX1K5",
};

// ✅ Khởi tạo Firebase
const app = initializeApp(firebaseConfig);

// ✅ Khởi tạo Firestore & Auth
export const db = getFirestore(app);
export const auth = getAuth(app);
