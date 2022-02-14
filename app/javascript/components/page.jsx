import React, { useEffect, useState, useRef } from 'react'
import Paper from 'paper';
import { Layer } from './layer';

export function Page({ activeTool, activeColor }) {
  // owner layer corresponds to a layer_id of '0'
  // participant layer corresponds to a layer_id of '1'

  const canvasRef = useRef(null);
  const [paperScope, setPaperScope] = useState(null);
  const [ownerLayer, setOwnerLayer] = useState(null);
  const [participantLayer, setParticipantLayer] = useState(null);

  useEffect(() => {
    const scope = new Paper.PaperScope();
    const canvas = canvasRef.current;
    scope.setup(canvas);

    let owner, participant;

    owner = new Paper.Layer();
    scope.project.addLayer(owner);

    // only create participant layer if user is a participant of notebook
    if (!window.isOwner) {
      participant = new Paper.Layer();
      scope.project.addLayer(participant);
      participant.bringToFront();
    }

    setPaperScope(scope);
    setOwnerLayer(owner);

    if (!window.isOwner) {
      setParticipantLayer(participant);
    }
  }, []);

  // only render participant layer if user is a participant of notebook
  return (
    <div style={pageStyle}>
      <canvas ref={canvasRef} width='1017px' height='777px' style={canvasStyle} />
      <Layer
        layer={ownerLayer}
        layerId='0'
        activeTool={activeTool}
        activeColor={activeColor}
      />
      {!window.isOwner &&
        <Layer
          layer={participantLayer}
          layerId='1'
          activeTool={activeTool}
          activeColor={activeColor}
        />
      }
    </div>
  );
};

const pageStyle = {
  border: '2px solid black'
};

const canvasStyle = {
  background: 'none',
};