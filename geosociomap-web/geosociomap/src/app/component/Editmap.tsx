import React, { useState, useRef, useEffect, useCallback } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import MyLocationIcon from "@mui/icons-material/MyLocation";
import UndoIcon from "@mui/icons-material/Undo";
import RedoIcon from "@mui/icons-material/Redo";
import ClearIcon from "@mui/icons-material/Clear";
// import { useMapContext } from "../contexts/MapContext";
import { Divider } from "@mui/material";
// import RemoveCircleIcon from "@mui/icons-material/RemoveCircle";
import DeleteIcon from "@mui/icons-material/Delete";
import Search from "./Search";
import ModeIcon from "@mui/icons-material/Mode";
import { Point } from "../types";

mapboxgl.accessToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN as string

interface SelectedPointProps {
  selectedArea: Point[] | null;
  points: [number, number][]; 
  setPoints: React.Dispatch<React.SetStateAction<[number, number][]>>; 
  setSelectedPoint:  React.Dispatch<React.SetStateAction<Point[] | null>>; 
}

const Editmap: React.FC<SelectedPointProps> = ({
  selectedArea,
  points,
  setPoints,
  setSelectedPoint,
}) => {
  //   const [points, setPoints] = useState<[number, number][]>([]);
  const [isAddingPoints] = useState(false); 
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const [history, setHistory] = useState<[number, number][][]>([]);
  const [redoStack, setRedoStack] = useState<[number, number][][]>([]);
  const [userLocation, setUserLocation] = useState<[number, number] | null>(
    null
  );
  const [searchLocation, setSearchLocation] = useState<[number, number] | null>(
    null
  );
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const pointsRef = useRef<[number, number][]>(points);
  const [isDeleteMode, setIsDeleteMode] = useState(false);
  const [isInsertMode, setIsInsertMode] = useState(false);
  const [selectedPoints, setSelectedPoints] = useState<number[]>([]);
  pointsRef.current = points;

  useEffect(() => {
    if (selectedArea == null) return;
    const convertedPoints: [number, number][] = selectedArea.map(
      (point) => [point.lng, point.lat] as [number, number] 
    );
    setPoints(convertedPoints);
    if (mapRef.current) {
      const map = mapRef.current;
      updatePolygon(map, convertedPoints);
      updatePoints(map, points, selectedPoints);
    }
  }, [selectedArea]);

  useEffect(() => {
    console.log(points);
  }, [points]);

  useEffect(() => {
    if (mapRef.current) {
      const map = mapRef.current;

      if (map.getSource("polygon")) {
        map.removeLayer("polygon-layer");
        map.removeSource("polygon");
      }

      map.on("load", () => {
        map.addSource("polygon", {
          type: "geojson",
          data: {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                geometry: {
                  type: "Polygon",
                  coordinates: [points], 
                },
                properties: {},
              },
            ],
          },
        });

        map.addLayer({
          id: "polygon-layer",
          type: "fill",
          source: "polygon",
          paint: {
            "fill-color": "#3b82f6",
            "fill-opacity": 0.3,
          },
        });
      });

      console.log("Initial polygon set");
    }
  }, [points]);

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          setUserLocation([longitude, latitude]);
        },
        (error) => {
          console.error("Error getting user location:", error);
          setErrorMessage("Unable to fetch your location.");
        },
        { enableHighAccuracy: true }
      );
    } else {
      console.error("Geolocation is not supported by this browser.");
      setErrorMessage("Geolocation is not supported by your browser.");
    }
  }, []);

  const getCentroid = (points: Point[]): [number, number] => {
    const totalPoints = points.length;

    const sum = points.reduce(
      (acc, point) => {
        return {
          lat: acc.lat + point.lat,
          lng: acc.lng + point.lng,
        };
      },
      { lat: 0, lng: 0 }
    );

    const centroid = {
      lat: sum.lat / totalPoints,
      lng: sum.lng / totalPoints,
    };
    console.log([centroid.lng, centroid.lat]);
    return [centroid.lng, centroid.lat];
  };

  useEffect(() => {
    if (mapContainerRef.current && !mapRef.current) {
      //   const initialCenter = userLocation ||
      //     searchLocation || [100.523186, 13.736717];
      const map = new mapboxgl.Map({
        container: mapContainerRef.current,
        style: "mapbox://styles/mapbox/streets-v11",
        center: getCentroid(selectedArea!),
        zoom: 17,
      });
      mapRef.current = map;

      console.log("Map created");

      return () => {
        if (mapRef.current) {
          mapRef.current.remove();
          mapRef.current = null;
          console.log("Map removed");
        }
      };
    }
  }, []);

  useEffect(() => {
    if (mapRef.current) {
      const map = mapRef.current;

      //   if (userLocation) {
      //     new mapboxgl.Marker().setLngLat(userLocation).addTo(map);
      //     map.setCenter(userLocation);
      //   }

      if (searchLocation) {
        new mapboxgl.Marker()
          .setLngLat(searchLocation)
          .setPopup(new mapboxgl.Popup().setText("Search Location"))
          .addTo(map);
        map.setCenter(searchLocation);
      }

      console.log("Location updated");
    }
  }, [searchLocation]);

  const isPointNear = (
    point1: [number, number],
    point2: [number, number],
    tolerance: number
  ) => {
    const distance = Math.sqrt(
      Math.pow(point2[0] - point1[0], 2) + Math.pow(point2[1] - point1[1], 2)
    );
    return distance <= tolerance;
  };

  useEffect(() => {
    if (mapRef.current) {
      const map = mapRef.current;

      const handleClick = (event: mapboxgl.MapMouseEvent) => {
        const { lng, lat } = event.lngLat;
        const clickedPoint: [number, number] = [lng, lat];

        if (!isInsertMode) {
          setPoints((prevPoints) => {
            const updatedPoints = [...prevPoints, clickedPoint];

            setHistory((prevHistory) => {
              const lastPoints = prevHistory[prevHistory.length - 1];
              if (
                !lastPoints ||
                JSON.stringify(lastPoints) !== JSON.stringify(prevPoints)
              ) {
                return [...prevHistory, prevPoints];
              }
              return prevHistory;
            });

            setRedoStack([]);
            updatePolygon(map, updatedPoints);
            updatePoints(map, updatedPoints, selectedPoints);
            return updatedPoints;
          });
        } else {
          const handlePointClick = (index: number) => {
            if (selectedPoints.includes(index)) {
              setSelectedPoints((prev) => prev.filter((i) => i !== index));
            } else if (selectedPoints.length < 2) {
              setSelectedPoints((prev) => [...prev, index]);
            }
          };
          points.forEach((point, index) => {
            if (isPointNear(clickedPoint, point, 0.0005)) {
              handlePointClick(index);
            }
          });
          if (isInsertMode && selectedPoints.length === 2) {
            const [index1, index2] = selectedPoints;
            const pointsLength = points.length;
            const areAdjacent =
              Math.abs(index2 - index1) === 1 ||
              (index1 === 0 && index2 === pointsLength - 1) ||
              (index2 === 0 && index1 === pointsLength - 1);

            if (areAdjacent) {
              const newPoint: [number, number] = [lng, lat];

              setPoints((prevPoints) => {
                const updatedPoints = [...prevPoints];
                if (
                  (index1 === 0 && index2 === updatedPoints.length - 1) ||
                  (index2 === 0 && index1 === updatedPoints.length - 1)
                ) {
                  updatedPoints.push(newPoint);
                } else {
                  const insertIndex = Math.min(index1, index2) + 1;
                  updatedPoints.splice(insertIndex, 0, newPoint);
                }

                setHistory((prevHistory) => {
                  const lastPoints = prevHistory[prevHistory.length - 1];
                  if (
                    !lastPoints ||
                    JSON.stringify(lastPoints) !== JSON.stringify(updatedPoints)
                  ) {
                    return [...prevHistory, updatedPoints];
                  }
                  return prevHistory;
                });
                // updatePolygon(map, updatedPoints);
                updatePoints(map, updatedPoints, []);

               
                return updatedPoints;
              });
            } else {
              console.log(
                "Selected points are not adjacent, cannot insert a new point."
              );
            }
          }
        }
        if (isDeleteMode) {
          setPoints((prevPoints) => {
            const tolerance = 0.0005;
            const updatedPoints = prevPoints.filter(
              (point) => !isPointNear(point, clickedPoint, tolerance)
            );
            setHistory((prevHistory) => {
              const lastPoints = prevHistory[prevHistory.length - 1];
              if (
                !lastPoints ||
                JSON.stringify(lastPoints) !== JSON.stringify(updatedPoints)
              ) {
                return [...prevHistory, lastPoints];
              }
              return prevHistory;
            });
            setRedoStack([]);
            setSelectedPoint([]);
            updatePolygon(map, updatedPoints);
            updatePoints(map, updatedPoints, selectedPoints);
            return updatedPoints;
          });
        }
      };

      map.on("click", handleClick);
      return () => {
        map.off("click", handleClick);
      };
    }
  }, [mapRef, isAddingPoints, isDeleteMode, isInsertMode, selectedPoints]);

  useEffect(() => {
    const p: Point[] = points.map((newPoint) => ({
      lat: newPoint[1], 
      lng: newPoint[0],
    }));
    console.log("points");
    console.log(p);
    
    setSelectedPoint(p); 
    console.log(selectedArea);
  }, [points]);
  
  useEffect(() => {
   
      console.log("selectedArea");
      console.log(selectedArea);


  }, [selectedArea]);




  useEffect(() => {
    if (mapRef.current) {
      const map = mapRef.current;

      const updateMapPoints = () => {
        updatePoints(map, points, selectedPoints);
      };

      if (map.isStyleLoaded()) {
        updateMapPoints();
      } else {
        map.on("load", updateMapPoints);
      }
      return () => {
        map.off("load", updateMapPoints);
      };
    }
  }, [mapRef, points, selectedPoints]);

  const updatePoints = useCallback(
    (
      map: mapboxgl.Map,
      points: [number, number][],
      selectedPoints: number[]
    ) => {
      if (map.getSource("points")) {
        map.removeLayer("points-layer");
        map.removeSource("points");
      }

      map.addSource("points", {
        type: "geojson",
        data: {
          type: "FeatureCollection",
          features: points.map((point, index) => ({
            type: "Feature",
            geometry: {
              type: "Point",
              coordinates: point,
            },
            properties: {
              color: selectedPoints.includes(index) ? "#93c5fd" : "#3b82f6",
            },
          })),
        },
      });

      map.addLayer({
        id: "points-layer",
        type: "circle",
        source: "points",
        paint: {
          "circle-radius": 6,
          "circle-color": ["get", "color"],
        },
      });
    },
    []
  );

  const updatePolygon = useCallback(
    (map: mapboxgl.Map, points: [number, number][]) => {
      if (map.getSource("polygon")) {
        map.removeLayer("polygon-layer");
        map.removeSource("polygon");
      }

      if (points.length > 2) {
        map.addSource("polygon", {
          type: "geojson",
          data: {
            type: "Feature",
            geometry: {
              type: "Polygon",
              coordinates: [[...points, points[0]]],
            },
            properties: {},
          },
        });

        map.addLayer({
          id: "polygon-layer",
          type: "fill",
          source: "polygon",
          layout: {},
          paint: {
            "fill-color": "#3b82f6",
            "fill-opacity": 0.3,
          },
        });
      }
    },
    []
  );

  const undo = () => {
    if (history.length === 0) return;
    const lastState = history[history.length - 1];

    setRedoStack((prevRedoStack) => [points, ...prevRedoStack]);
    setHistory(history.slice(0, -1));
    setPoints(lastState);
    updatePolygon(mapRef.current!, lastState);
    updatePoints(mapRef.current!, lastState, selectedPoints);
  };

  const redo = () => {
    if (redoStack.length === 0) return;

    const nextState = redoStack[0];
    setPoints(nextState);
    setHistory((prevHistory) => [...prevHistory, points]);
    setRedoStack(redoStack.slice(1));
    updatePolygon(mapRef.current!, nextState);
    updatePoints(mapRef.current!, nextState, selectedPoints);
  };

  useEffect(() => {
    console.log("History:", history);
    console.log("RedoStack:", redoStack);
  }, [history, redoStack]);

  const clearAll = () => {
    setPoints([]);
    setHistory([]);
    setRedoStack([]);
    setSelectedPoints([]);
    if (mapRef.current) {
      mapRef.current.removeLayer("points-layer");
      mapRef.current.removeSource("points");
      mapRef.current.removeLayer("polygon-layer");
      mapRef.current.removeSource("polygon");
    }
  };

  const goToCurrentLocation = () => {
    if (mapRef.current && userLocation) {
      mapRef.current.flyTo({
        center: userLocation,
        zoom: 14,
        essential: true,
      });
    }
  };

  const handleSearchResult = (lng: number, lat: number) => {
    setSearchLocation([lng, lat]);
  };

  //   const handlePointClick = (index: number) => {
  //     if (isInsertMode) {
  //       console.log("Insert mode is active");

  //       if (selectedPoints.length < 2 && !selectedPoints.includes(index)) {
  //         setSelectedPoints((prev) => {
  //           const newSelectedPoints = [...prev, index];
  //           console.log("Selected point:", newSelectedPoints);
  //           return newSelectedPoints;
  //         });
  //       }
  //     } else {
  //       console.log("Insert mode is not active");
  //     }
  //   };

  const toggleInsertMode = () => {
    if (isInsertMode) {
      setSelectedPoints([]);
      if (mapRef.current) {
        updatePoints(mapRef.current, points, []); 
      }
    }
    setIsInsertMode(!isInsertMode);
  };

  return (
    <div className="w-full h-screen relative flex">
      <div ref={mapContainerRef} className="w-full h-full" />
      <div className="absolute bottom-20 right-4 rounded-md shadow-md">
        <button
          onClick={goToCurrentLocation}
          className="absolute right-4 bg-white text-stone-500 py-2 px-2 rounded-md shadow-md hover:bg-stone-100 transition"
        >
          <MyLocationIcon />
        </button>
      </div>
      <Search onSearchResult={handleSearchResult} />

      <div className="absolute top-4 right-4 rounded-md shadow-md">
        <div className="absolute right-4 ">
          <button className="p-2 text-blue-500" onClick={clearAll}>
            <ClearIcon />
          </button>
          <div className="py-1 px-1 bg-white text-stone-500 shadow-md rounded-md  ">
            <button
              className="px-1 py-2  hover:bg-stone-100 transition"
              onClick={undo}
            >
              <UndoIcon />
            </button>
            <Divider />
            <button
              className="px-1 py-2 hover:bg-stone-100 transition"
              onClick={redo}
            >
              <RedoIcon />
            </button>
          </div>
          <button
            className="p-2 text-blue-500"
            onClick={() => setIsDeleteMode(!isDeleteMode)}
          >
            {isDeleteMode ? (
              <div>
                <DeleteIcon className="text-red-500" />
              </div>
            ) : (
              <div>
                <DeleteIcon className="text-neutral-500" />
              </div>
            )}
          </button>
          <button className="p-2 text-blue-500" onClick={toggleInsertMode}>
            {isInsertMode ? (
              <div>
                <ModeIcon className="text-blue-500" />
              </div>
            ) : (
              <div>
                <ModeIcon className="text-neutral-500" />
              </div>
            )}
          </button>
        </div>
      </div>
      <div className="absolute bottom-0 left-0 p-4 bg-white"></div>
      {errorMessage && (
        <div className="absolute top-0 left-0 p-4 bg-red-500 text-white">
          {errorMessage}
        </div>
      )}
      {isDeleteMode && (
        <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-white py-2 px-4 rounded-lg shadow-md">
          ลบตำแหน่ง
        </div>
      )}
      {isInsertMode && (
        <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-white py-2 px-4 rounded-lg shadow-md">
          แทรกตำแหน่ง
        </div>
      )}
    </div>
  );
};

export default Editmap;
