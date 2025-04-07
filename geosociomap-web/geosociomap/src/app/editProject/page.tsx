"use client";

// import Map from "../component/Map";
// import Sidebar from "../component/Sidebar";
import { MapProvider } from "../contexts/MapContext";
import { useEffect, useState } from "react";
// import { useRouter } from "next/navigation";
import { useRef } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import EditSidebar from "../component/EditSidebar";
import { Point, Project } from "../types";
import Editmap from "../component/Editmap";

const EditProject: React.FC = () => {
  //   const router = useRouter();
  const [projectId, setProjectId] = useState<string | null>(null);
  const [project, setProject] = useState<Project | null>(null);
  const [points, setPoints] = useState<[number, number][]>([]);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const [selectedPoints, setSelectedPoints] = useState<Point[] | null>(null);

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

  useEffect(() => {
    const searchParams = new URLSearchParams(window.location.search);
    const id = searchParams.get("id"); 
    if (id) {
      setProjectId(id); 
    }
  }, []);

  useEffect(() => {
    if (projectId) {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      fetch(`${API_BASE_URL}/project/${projectId}`)
        .then((response) => response.json())
        .then((data) => setProject(data));
    }
  }, [projectId]);

  useEffect(() => {
  
    setSelectedPoints(points.map(([lng, lat]) => ({ lat, lng })));
  }, [points]);

  const setSelectedPoint = (p: Point[] | null | ((prevState: Point[] | null) => Point[] | null)) => {
    setSelectedPoints(p);
  };
  
  return (
    <MapProvider>
      <div className="flex h-screen">
        {project?.selectedPoints && (
          <EditSidebar
            projectId={projectId}
            Name={project?.projectName || null}
            selectedPoints={selectedPoints}
            userIds={project.userIds}
            p={points}
          />
        )}
        {project?.selectedPoints && (
          <div className="w-screen">
            <Editmap
              selectedArea={project?.selectedPoints}
              points={points}
              setPoints={setPoints}
              setSelectedPoint={setSelectedPoint}
            />
          </div>
        )}
      </div>
    </MapProvider>
  );
};

export default EditProject;
