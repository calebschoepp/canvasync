import React, { useCallback, useEffect, useRef, useState } from "react"
import Paper from 'paper';

export default () => {

    const canvasRef = useRef(null);
    const pathRef = useRef(null);
    const [pageState, setPageState] = useState(0);
    const [penState, setPenState] = useState("pen");
    const [colorState, setColorState] = useState("black");
    const [pathState, setPathState] = useState([]);

    useEffect(() => {
        const canvas = canvasRef.current;
        Paper.setup(canvas);
        paperHandler();
    }, []);

    useEffect(() => {
        pathRef.current = null;
        paperHandler();
    }, [pathState.length, penState, colorState]);

    const canvasToolCallback = useCallback((event) => {
        if (pathRef.current) {
            setPathState(oldPaths => [...oldPaths, pathRef.current]);
        }
        setPenState(event.currentTarget.innerText.toLowerCase());
    });

    const colorToolCallback = useCallback((event) => {
        if (pathRef.current) {
            setPathState(oldPaths => [...oldPaths, pathRef.current]);
        }
        setColorState(event.target.value);
    });

    const pageButtonHandler = useCallback((pageDelta) => {
        const newPageState = Math.max(pageState + pageDelta, 0);
        if (newPageState >= Paper.projects.length) {
            const canvas = canvasRef.current;
            new Paper.Project(canvas);
        }
        console.log(newPageState);
        Paper.projects[newPageState].activate();
        setPageState(newPageState);
        paperHandler();
    });

    const paperHandler = () => {
        let path = null;

        let rect = null;
        let p1 = null;
        let p2 = null;

        Paper.view.onMouseDown = (event) => {
            if (penState === "pen") {
                Paper.project.deselectAll();
                pathRef.current = new Paper.Path();
            } else if (penState === "eraser") {
                Paper.project.deselectAll();
                path = new Paper.Path();
            }
            else if (penState === "select") {
                p1 = new Paper.Point(event.point.x, event.point.y);
                if (rect && p1.isInside(rect) && Paper.project.selectedItems.length > 0) {
                    rect = null;
                    path = null;
                } else {
                    Paper.project.deselectAll();
                    rect = new Paper.Rectangle();
                    path = new Paper.Path.Rectangle(rect);
                }
            } else if (penState === "text") {
                Paper.project.deselectAll();
                const point = new Paper.Point(event.point.x, event.point.y);
                pathRef.current = new Paper.PointText({
                    point: point,
                    fontFamily: 'serif',
                    fontSize: 25,
                });
                pathRef.current.fullySelected = true;
            }
            if (penState !== "pen" && penState !== "text" && Paper.project.selectedItems.length === 0) {
                path.strokeColor = "black";
                path.strokeWidth = 3;
                path.dashArray = [10, 12];
            } else if (Paper.project.selectedItems.length === 0 || (penState === "text")) {
                pathRef.current.strokeColor = colorState;
                pathRef.current.strokeWidth = penState === "pen" ? 3 : 1;
            }
        };

        Paper.view.onMouseDrag = (event) => {
            if (penState === "pen") {
                pathRef.current.add(event.point);
            } else if (penState === "eraser") {
                path.add(event.point);
             } else if (penState === "select") {
                p2 = new Paper.Point(event.point.x, event.point.y);
                if (Paper.project.selectedItems.length === 0) {
                    rect.set(p1, p2);
                    path.segments = [
                        new Paper.Segment(new Paper.Point(rect.x, rect.y)),
                        new Paper.Segment(new Paper.Point(rect.x + rect.width, rect.y)),
                        new Paper.Segment(new Paper.Point(rect.x + rect.width, rect.y + rect.height)),
                        new Paper.Segment(new Paper.Point(rect.x, rect.y + rect.height)),
                    ];
                }
            }
        };

        Paper.view.onMouseUp = () => {
            if (penState === "pen") {
                pathRef.current.simplify(10);
                setPathState(oldPaths => [...oldPaths, pathRef.current]);
                pathRef.current = null;
            } else if (penState === "eraser") {
                const newPathState = [];
                for (p of pathState) {
                    if (p.parent === Paper.project.activeLayer && path.intersects(p)) {
                        p.remove();
                    } else {
                        newPathState.push(p);
                    }
                    setPathState(newPathState);
                }
                path.remove();
                path = null;
            } else if (penState === "select") {
                if (Paper.project.selectedItems.length === 0) {
                    for (p of pathState) {
                        // check for path
                        if (p.parent === Paper.project.activeLayer && p.segments && p.segments.every((segment) => path.contains(segment.point))) {
                            p.fullySelected = true;
                        } else if (p.content && p.isInside(rect)) { // check for text
                            p.fullySelected = true;
                        }
                    }
                    path.remove();
                    path = null;
                } else {
                    const newPathState = [];
                    for (p of pathState) {
                        if (Paper.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
                            p.translate(p2.subtract(p1));
                            p.fullySelected = false;
                        }
                        newPathState.push(p);
                    }
                    setPathState(newPathState);
                }
            }
        };

        Paper.view.onKeyDown = (event) => {
            if (penState !== "text" && penState !== "select") {
                return;
            }
            Paper.project.selectedItems.length
            if (penState === "select" && event.key === "delete" && Paper.project.selectedItems.length) {
                const newPathState = [];
                for (p of pathState) {
                    if (Paper.project.selectedItems.find((selectedItem) => selectedItem.id === p.id)) {
                        p.remove();
                    } else {
                        newPathState.push(p);
                    }
                }
                setPathState(newPathState);
            } else if (event.key === "escape" || event.key === "enter") {
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
                <input type="color" onChange={colorToolCallback}/>
                <button className="primary-button" onClick={canvasToolCallback}>Eraser</button>
                <button className="primary-button" onClick={canvasToolCallback}>Select</button>
                <button className="primary-button" onClick={canvasToolCallback}>Text</button>
            </div>
            <div className="flex flex-col">
                <canvas ref={canvasRef} width="1017px" height="777px" id="canvas" style={{ border: "1px solid black" }} />
                <h4>{`${pageState+1}/${Paper.projects.length}`}</h4>
                <div className="flex flex-row">
                    <button className="primary-button" onClick={() => pageButtonHandler(-1)}>Prev</button>
                    <button className="primary-button" onClick={() => pageButtonHandler(1)}>{pageState === Paper.projects.length - 1 ? "Add" : "Next"}</button>
                </div>
            </div>
        </div>
    );
};