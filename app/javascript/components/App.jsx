import React, { useCallback, useEffect, useRef, useState } from "react"
import Paper from 'paper';

export default () => {

    const canvasRef = useRef(null);
    const [penState, setPenState] = useState("pen");
    const [pathState, setPathState] = useState([]);

    useEffect(() => {
        const canvas = canvasRef.current;
        Paper.setup(canvas);
        paperHandler("pen");
    }, []);

    useEffect(() => {
        paperHandler(penState);
    }, [pathState.length, penState]);

    const penCallback = useCallback(() => {
        setPenState("pen");
    });

    const eraserCallback = useCallback(() => {
        setPenState("eraser");
    });

    const selectCallback = useCallback(() => {
        setPenState("select");
    });

    const textCallback = useCallback(() => {
        setPenState("text");
    });

    const paperHandler = (penState) => {
        let path = null;

        let rect = null;
        let p1 = null;

        Paper.view.onMouseDown = (event) => {

            // todo: ensure to add previous text to pathState, especially when changing pen tool
            if (path) {
                setPathState(oldPaths => [...oldPaths, path]);
            }

            Paper.project.deselectAll();
            if (penState === "pen" || penState === "eraser") {
                path = new Paper.Path();
            } else if (penState === "select") {
                rect = new Paper.Rectangle();
                path = new Paper.Path.Rectangle(rect);
                p1 = new Paper.Point(event.point.x, event.point.y);
            } else if (penState === "text") {
                const point = new Paper.Point(event.point.x, event.point.y);
                path = new Paper.PointText({
                    point: point,
                    fontFamily: 'Courier New',
                    fontWeight: 'bold',
                    fontSize: 25,
                });
                path.fullySelected = true;
            }
            path.strokeColor = "black";
            if (penState !== "pen") {
                path.dashArray = [10, 12];
            }
            path.strokeWidth = 3;
        };

        Paper.view.onMouseDrag = (event) => {
            if (penState === "pen" || penState === "eraser") {
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
                path.simplify();
                setPathState(oldPaths => [...oldPaths, path]);
                path = null;
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
                setPathState(oldPaths => [...oldPaths, path]);
                path.fullySelected = false;
                path = null;
            } else if (event.key === "backspace") {
                path.content = path.content.slice(0, -1);
            }
            if (penState === "text" && path && event.character !== "") {
                path.content += event.character;
            }
        };

        Paper.view.draw();
    };

    return (
        <div className="flex flex-row">
            <div className="flex flex-col">
                <button className="primary-button" onClick={penCallback}>Pen</button>
                <button className="primary-button" onClick={eraserCallback}>Eraser</button>
                <button className="primary-button" onClick={selectCallback}>Select</button>
                <button className="primary-button" onClick={textCallback}>Text</button>
            </div>
            <canvas ref={canvasRef} width="1017px" height="777px" id="canvas" style={{ border: "1px solid black" }} />
        </div>
    );
};