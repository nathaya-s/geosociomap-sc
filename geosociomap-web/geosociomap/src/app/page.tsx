// import Image from "next/image";
"use client";

import { Sarabun } from "next/font/google";
// import Login from "./login/page";
import HomePage from "./main/page";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "./hooks/useAuth";

// import { getAuth } from "firebase/auth";
// import axios from "axios";

// const auth = getAuth();
const mitr = Sarabun({
  weight: ["400", "500", "600", "700"],
  subsets: ["thai", "latin"],
  display: "swap",
});

export default function Home() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    } else {
      router.push("/main");
    }
  }, [loading, user, router]);

  if (loading) return <p>Loading...</p>;

  if (!user) return null;
  return (
    <div className={mitr.className}>
      <HomePage />
    </div>
  );
}
