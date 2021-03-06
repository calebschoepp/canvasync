import React, { useEffect, useState, useRef } from 'react'
import Paper from 'paper';
import { Layer } from './layer';
import * as pdfJS from "pdfjs-dist/build/pdf";

// Mandated by FR-8: Open.Notebook through FR-12: ParticipantEdit.Canvas
export function Page({ activeTool, activeColor, ownerLayerId, participantLayerId, pageNumber }) {
  const canvasRef = useRef(null);
  const [raster, setRaster] = useState(null);
  const [paperScope, setPaperScope] = useState(null);
  const [background, setBackground] = useState(null);
  const [ownerLayer, setOwnerLayer] = useState(null);
  const [participantLayer, setParticipantLayer] = useState(null);

  useEffect(() => {
    // Defer PaperScope creation until after PDF background raster is created
    if (raster) {
      const scope = new Paper.PaperScope();
      const canvas = canvasRef.current;
      const width = canvas.width;
      const height = canvas.height;
      scope.setup(canvas);

      let rasterLayer, owner, participant;

      // Draw background PDF raster only if there is a background PDF page for this page number
      if (raster !== -1) {
        rasterLayer = new Paper.Layer();
        scope.project.addLayer(rasterLayer);
        rasterLayer.activate();
        const paperRaster = new Paper.Raster(raster);
        // Fit raster in middle of canvas
        paperRaster.position = new Paper.Point(width / 2, height / 2);
      }

      owner = new Paper.Layer();
      scope.project.addLayer(owner);
      owner.bringToFront();

      // Only create participant layer if user is a participant of notebook
      if (window.isOwner) {
        owner.activate();
      } else {
        participant = new Paper.Layer();
        scope.project.addLayer(participant);
        participant.bringToFront();
        participant.activate();
      }

      setPaperScope(scope);

      if (raster !== -1) {
        setBackground(rasterLayer);
      }

      setOwnerLayer(owner);

      if (!window.isOwner) {
        setParticipantLayer(participant);
      }
    }
  }, [raster]);

  // Mandated by FR-9: Edit.Canvas
  useEffect(() => {
    pdfJS.GlobalWorkerOptions.workerSrc =
      window.location.origin + '/pdf.worker.min.js';
    if (window.backgroundPdf) {
      pdfJS.getDocument(window.backgroundPdf).promise.then((pdf) => {
        pdf.getPage(pageNumber).then((page) => {
          const viewport = page.getViewport({ scale: 1.5 });
    
          // Prepare canvas using PDF page dimensions.
          const canvas = canvasRef.current;
          const canvasContext = canvas.getContext('2d');
          canvas.height = viewport.height;
          canvas.width = viewport.width;
    
          // Render PDF page into canvas context.
          const renderContext = { canvasContext, viewport };
          page.render(renderContext).promise.then(() => {
            // set raster image source as pdf canvas image
            const image = new Image();
            image.src = canvas.toDataURL()
            setRaster(image);
          });
        }).catch(() => {
          // there is no page in document with given page number so set raster as -1 
          setRaster(-1);
        });
      });
    } else {
      setRaster(-1);
    }
  }, []);

  // Only render participant layer if user is a participant of notebook.
  // Layer id corresponds to id of layer in database.
  return (
    <div style={pageStyle}>
      <canvas data-testid={`canvasync-canvas-${ownerLayerId}-${participantLayerId}`} ref={canvasRef} width='918px' height='1188px' style={canvasStyle} />
      <Layer
        scope={window.isOwner ? paperScope : undefined}
        background={background}
        layer={ownerLayer}
        layerId={ownerLayerId}
        activeTool={activeTool}
        activeColor={activeColor}
      />
      {!window.isOwner &&
        <Layer
          scope={paperScope}
          layer={participantLayer}
          layerId={participantLayerId}
          activeTool={activeTool}
          activeColor={activeColor}
        />
      }
    </div>
  );
}

const pageStyle = {
  margin: '8px auto',
  border: '2px solid black',
  display: 'flex',
  justifyContent: 'center'
};

const canvasStyle = {
  background: 'none',
};