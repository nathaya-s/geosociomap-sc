// pages/forgot-password.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
// import PasswordIcon from "@mui/icons-material/Password";
import KeyIcon from '@mui/icons-material/Key';
import { sendPasswordResetEmail } from "firebase/auth";
import { Sarabun } from "next/font/google";
import { auth } from "../firebase";

const sarabun = Sarabun({
    weight: ["400", "500", "600", "700"],
    subsets: ["thai", "latin"],
    display: "swap",
  });

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const router = useRouter();

  const handlePasswordReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage("");
    setError("");

    try {
      await sendPasswordResetEmail(auth, email);
      setMessage("ลิงก์สำหรับรีเซ็ตรหัสผ่านได้ถูกส่งไปยังอีเมลของคุณแล้ว");
    } catch (err) {
      // setError(err.message);
    }
  };

  const goToLogin = () => {
    router.push("/login");
  };

  return (
    <div className={`flex gap-4 justify-center content-center text-center h-screen	 items-center ${sarabun.className}`}>
      <div className="flex flex-col gap-8  rounded-xl    p-8 h-100 justify-center items-center text-center border shadow-md border-neutral-300	align-center  place-self-center ">
        <div className="flex place-items-center   bg-blue-100  max-h-36 min-h-36 min-w-36 max-w-36 rounded-full justify-center align-center " >
            <KeyIcon className=" text-blue-500 text-7xl" />
        </div>
        <div>
        <h2 className="font-bold text-blue-500 text-xl">ตั้งค่ารหัสผ่านใหม่</h2>
        <p>กรอกอีเมลของคุณเพื่อขอรับลิงก์รีเซ็ตรหัสผ่าน</p>
        </div>
        <form className="flex flex-col w-80 gap-4" onSubmit={handlePasswordReset}>
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="p-2.5 text-base border-solid	border-1 border-black outline-none border border-neutral-200 rounded-lg" 
          />
          <button className="p-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg "  type="submit">ยืนยัน</button>
          <text onClick={goToLogin}>
          <a className="text-sm text-neutral-500 cursor-pointer" >ย้อนกลับ</a>
        </text>
        </form>
        {message && <p className="message success">{message}</p>}
        {error && <p className="message error">{error}</p>}
       
      </div>
    </div>
  );
};

export default ForgotPassword;
