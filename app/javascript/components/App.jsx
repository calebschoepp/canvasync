import React, { useCallback, useEffect, useRef, useState } from "react"
import Paper from 'paper';

export default () => {

    const canvasRef = useRef(null);
    const pathRef = useRef(null);
    const [penState, setPenState] = useState("pen");
    const [pathState, setPathState] = useState([]);

    useEffect(() => {
        const canvas = canvasRef.current;
        Paper.setup(canvas);
        paperHandler("pen");
    }, []);

    useEffect(() => {
        pathRef.current = null;
        paperHandler(penState);
    }, [pathState.length, penState]);

    const canvasToolCallback = useCallback((event) => {
        if (pathRef.current) {
            setPathState(oldPaths => [...oldPaths, pathRef.current]);
        }
        setPenState(event.currentTarget.innerText.toLowerCase());
    });

    const paperHandler = (penState) => {
        let path = null;

        let rect = null;
        let p1 = null;

        Paper.view.onMouseDown = (event) => {
            Paper.project.deselectAll();
            if (penState === "pen") {
                pathRef.current = new Paper.Path();
            } else if (penState === "eraser") {
                path = new Paper.Path();
            }
            else if (penState === "select") {
                rect = new Paper.Rectangle();
                path = new Paper.Path.Rectangle(rect);
                p1 = new Paper.Point(event.point.x, event.point.y);
            } else if (penState === "text") {
                const point = new Paper.Point(event.point.x, event.point.y);
                pathRef.current = new Paper.PointText({
                    point: point,
                    fontFamily: 'serif',
                    fontSize: 25,
                });
                pathRef.current.fullySelected = true;
            }
            if (penState !== "pen" && penState !== "text") {
                path.strokeColor = "black";
                path.strokeWidth = 3;
                path.dashArray = [10, 12];
            } else {
                pathRef.current.strokeColor = "black";
                pathRef.current.strokeWidth = penState === "pen" ? 3 : 1;
            }
        };

        Paper.view.onMouseDrag = (event) => {
            if (penState === "pen") {
                pathRef.current.add(event.point);
            } else if (penState === "eraser") {
                path.add(event.point);
             } else if (penState === "select") {
                const p2 = new Paper.Point(event.point.x, event.point.y);
                rect.set(p1, p2);
                path.segments = [
                    new Paper.Segment(new Paper.Point(rect.x, rect.y)),
                    new Paper.Segment(new Paper.Point(rect.x + rect.width, rect.y)),
                    new Paper.Segment(new Paper.Point(rect.x + rect.width, rect.y + rect.height)),
                    new Paper.Segment(new Paper.Point(rect.x, rect.y + rect.height)),
                ]
            }
        };

        Paper.view.onMouseUp = () => {
            if (penState === "pen") {
                pathRef.current.simplify();
                setPathState(oldPaths => [...oldPaths, pathRef.current]);
                pathRef.current = null;
            } else if (penState === "eraser") {
                const newPathState = [];
                for (p of pathState) {
                    if (path.intersects(p)) {
                        p.remove();
                    } else {
                        newPathState.push(p);
                    }
                    setPathState(newPathState);
                }
                path.remove();
                path = null;
            } else if (penState === "select") {
                for (p of pathState) {
                    // check for path
                    if (p.segments && p.segments.every((segment) => path.contains(segment.point))) {
                        p.fullySelected = true;
                    } else if (p.content && p.isInside(rect)) { // check for text
                        p.fullySelected = true;
                    }
                }
                path.remove();
                path = null;
            }
        };

        Paper.view.onKeyDown = (event) => {
            if (penState !== "text") {
                return;
            }
            if (event.key === "escape" || event.key === "enter") {
                setPathState(oldPaths => [...oldPaths, pathRef.current]);
                pathRef.current.fullySelected = false;
                pathRef.current = null;
            } else if (event.key === "backspace") {
                path.content = pathRef.current.content.slice(0, -1);
            }
            if (penState === "text" && pathRef.current && event.character !== "") {
                pathRef.current.content += event.character;
            }
        };

        Paper.view.draw();
    };

    return (
        <div className="flex flex-row">
            <div className="flex flex-col">
                <button className="primary-button" onClick={canvasToolCallback}>Pen</button>
                <button className="primary-button" onClick={canvasToolCallback}>Eraser</button>
                <button className="primary-button" onClick={canvasToolCallback}>Select</button>
                <button className="primary-button" onClick={canvasToolCallback}>Text</button>
            </div>
            <canvas ref={canvasRef} width="1017px" height="777px" id="canvas" style={{ border: "1px solid black" }} />
        </div>
    );
};