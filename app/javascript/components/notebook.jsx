import React, { useState, useCallback } from 'react'
import { Page } from './page';

export const CanvasTools = {
  pen: 'Pen',
  eraser: 'Eraser',
  select: 'Select',
  text: 'Pen',
}

export function Notebook() {
  const [activeTool, setActiveTool] = useState(CanvasTools.pen);
  const [activeColor, setActiveColor] = useState('#00000');

  const canvasToolCallback = useCallback((event) =>
    setActiveTool(event.target.innerText)
  );
  const colorToolCallback = useCallback((event) =>
    setActiveColor(event.target.value)
  );

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