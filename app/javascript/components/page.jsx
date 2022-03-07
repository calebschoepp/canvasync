import React, { useEffect, useState, useRef } from 'react'
import Paper from 'paper';
import { Layer } from './layer';


export function Page({ activeTool, activeColor, ownerLayerId, participantLayerId }) {
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

  // Only render participant layer if user is a participant of notebook.
  // Layer id corresponds to id of layer in database.
  return (
    <div style={pageStyle}>
      <canvas ref={canvasRef} width='1017px' height='777px' style={canvasStyle} />
      <Layer
        scope={paperScope}
        layer={ownerLayer}
        isOwner={true}
        layerId={ownerLayerId}
        activeTool={activeTool}
        activeColor={activeColor}
      />
      {!window.isOwner &&
        <Layer
          scope={paperScope}
          layer={participantLayer}
          isOwner={false}
          layerId={participantLayerId}
          activeTool={activeTool}
          activeColor={activeColor}
        />
      }
    </div>
  );
}

const pageStyle = {
  border: '2px solid black'
};

const canvasStyle = {
  background: 'none',
};