import React, { useCallback, useEffect, useRef, useState } from "react"
import Paper from 'paper';

export default () => {

    const canvasRef = useRef(null);
    const [pathState, setPathState] = useState([]);

    useEffect(() => {
        const canvas = canvasRef.current;
        Paper.setup(canvas);
        paperHandler("pen");
    }, []);

    const penCallback = useCallback(() => {
        paperHandler("pen");
    });

    const eraserCallback = useCallback(() => {
        paperHandler("eraser");
    });

    const selectCallback = useCallback(() => {
        paperHandler("select");
    });

    const paperHandler = (penState) => {
        let path = null;
        let rect = null;
        let p1 = null;

        Paper.view.onMouseDown = (event) => {
            Paper.project.deselectAll();
            if (penState === "pen" || penState === "eraser") {
                path = new Paper.Path();
            } else {
                rect = new Paper.Rectangle();
                path = new Paper.Path.Rectangle(rect);
                p1 = new Paper.Point(event.point.x, event.point.y);
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
            } else {
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
            } else if (penState === "eraser") {
                const newPathState = [];
                for (p of pathState) {
                    if (path.getIntersections(p).length) {
                        p.remove();
                    } else {
                        newPathState.push(p);
                    }
                    setPathState(newPathState);
                }
                path.remove();
            } else {
                for (p of pathState) {
                    if (p.segments.every((segment) => path.contains(segment.point))) {
                        p.fullySelected = true;
                    }
                }
                path.remove();
            }
        }

        Paper.view.draw();
    };

    return (
        <div>
            <button className="primary-button" onClick={penCallback}>Pen</button>
            <button className="primary-button" onClick={eraserCallback}>Eraser</button>
            <button className="primary-button" onClick={selectCallback}>Select</button>
            <canvas ref={canvasRef} width="1017px" height="777px" id="canvas" style={{ border: "1px solid black" }} />
        </div>
    );
};