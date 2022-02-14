import React, { useState, useCallback } from 'react'
import { Page } from './page';

export const CanvasTools = {
  pen: 'Pen',
  eraser: 'Eraser',
  select: 'Select',
  text: 'Text',
}

export function Notebook() {
  const [activeTool, setActiveTool] = useState(CanvasTools.pen);
  const [activeColor, setActiveColor] = useState('#00000');

  const canvasToolCallback = useCallback((event) => {
    setActiveTool(event.target.innerText);

    /* Nayan's code */
    // if (pathRef.current) {
    //   setPathState(oldPaths => [...oldPaths, pathRef.current]);
    // }
    // setPenState(event.currentTarget.innerText.toLowerCase());
  });
  const colorToolCallback = useCallback((event) => {
    setActiveColor(event.target.value);

    /* Nayan's code */
    // if (pathRef.current) {
    //   setPathState(oldPaths => [...oldPaths, pathRef.current]);
    // }
    // setColorState(event.target.value);
  });

  return (
    <div className='flex flex-row'>
      <div className='flex flex-col'>
        <input type='color' value={activeColor} onChange={colorToolCallback} />
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.pen}</button>
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.eraser}</button>
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.select}</button>
        <button className='primary-button' onClick={canvasToolCallback}>{CanvasTools.text}</button>
      </div>
      <Page activeTool={activeTool} activeColor={activeColor} />
    </div>
  );
};