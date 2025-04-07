"use client";

import { useAuth } from "../hooks/useAuth";
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useRef } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import Map from "../component/Map";
import Sidebar from "../component/Sidebar";
import { MapProvider } from "../contexts/MapContext";

const CreateProject = () => {
  const { user, loading } = useAuth();
  const router = useRouter();
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    }
  }, [loading, user, router]);

  useEffect(() => {
    if (map.current) return;

    if (mapContainerRef.current) {
      map.current = new mapboxgl.Map({
        container: mapContainerRef.current,
        style: "mapbox://styles/mapbox/streets-v11",
        center: [-74.5, 40],
        zoom: 9,
      });
    }

    return () => map.current?.remove();
  }, []);

  if (loading) return <p>Loading...</p>;

  if (!user) return null;
  return (
    <MapProvider>
      <div className="flex h-screen">
        <Sidebar />
        <div className="w-screen">
          <Map />
        </div>
      </div>
    </MapProvider>
  );
};
export default CreateProject;
