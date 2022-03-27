import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faPen, faEraser, faBorderTopLeft, faFont } from '@fortawesome/free-solid-svg-icons'
import { CanvasTools } from './notebook';

const ColorPalette = [
  '#3a86ff',
  '#8338ec',
  '#ff006e',
  '#fb5607',
  '#ffbe0b',
];

export const Toolbar = ({ activeColor, activeTool, onCanvasToolChange, onColorToolChange }) => {

  const colorButtons = [];
  for (let i = 0; i < ColorPalette.length; i++) {
    colorButtons.push(<button
      className='primary-button'
      onClick={() => onColorToolChange(ColorPalette[i])}
      style={colorPaletteStyle(ColorPalette[i])}
      key={i} />
    );
  }

  return (
    <div className='flex flex-col sticky items-center card mx-auto my-auto' style={toolBarStyle}>
      <div className='flex flex-row justify-center'>
        {colorButtons}
      </div>
      <input className='w-full' type='color' value={activeColor} style={colorInputStyle} onChange={(event) => onColorToolChange(event.target.value)} />
      <div className='flex flex-row justify-center'>
        <button className={activeTool === CanvasTools.pen ? 'primary-button' : 'secondary-button'} style={toolButtonStyle} onClick={() => onCanvasToolChange(CanvasTools.pen)}>
          <FontAwesomeIcon icon={faPen} />
        </button>
        <button className={activeTool === CanvasTools.eraser ? 'primary-button' : 'secondary-button'} style={toolButtonStyle} onClick={() => onCanvasToolChange(CanvasTools.eraser)}>
          <FontAwesomeIcon icon={faEraser} />
        </button>
        <button className={activeTool === CanvasTools.select ? 'primary-button' : 'secondary-button'} style={toolButtonStyle} onClick={() => onCanvasToolChange(CanvasTools.select)}>
          <FontAwesomeIcon icon={faBorderTopLeft} />
        </button>
        <button className={activeTool === CanvasTools.text ? 'primary-button' : 'secondary-button'} style={toolButtonStyle} onClick={() => onCanvasToolChange(CanvasTools.text)}>
          <FontAwesomeIcon icon={faFont} />
        </button>
      </div>
    </div>
  );
};

const colorPaletteStyle = (color) => ({
  backgroundColor: color,
  width: '32px',
  height: '32px',
  borderRadius: '16px',
  margin: '0 6px'
});

const toolBarStyle = {
  bottom: '12px'
};

const colorInputStyle = {
  height: '32px',
  marginTop: '8px'
};

const toolButtonStyle = {
  margin: '8px 8px'
};