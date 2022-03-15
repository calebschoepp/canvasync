import { useEffect, useRef, useState } from 'react'
import Paper from 'paper';
import { CanvasTools } from './notebook';
import consumer from '../channels/consumer';

// TODO: build in error handling with lost diffs
// TODO: make font size, line width, etc. variables

const DiffType = {
  Tangible: 'tangible',
  Remove: 'remove',
  Translate: 'translate'
}

export function Layer({ scope, layer, layerId, activeTool, activeColor }) {
  // Sequence number of next diff that is drawn or to accept
  let seq = useRef(0);

  // Other layer state
  const pathRef = useRef(null);
  const [tangibleSeqs, setTangibleSeqs] = useState([]);
  const [layerChannel, setLayerChannel] = useState(null);

  const setupSubscription = () => {
    return consumer.subscriptions.create({ channel: 'LayerChannel', layer_id: layerId }, {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log(`Connected to layer_channel_${layerId}...`);
      },

      disconnected() {
        // Called when the subscription has been terminated by the server
      },

      received(data) {
        // Called when there's incoming data on the websocket for this channel
        console.log(`Receiving diff(s) on layer_channel_${layerId}...`);

        if (Array.isArray(data)) {
          // Process array of incoming diffs (when we load existing diffs)
          data.forEach(diff => processIncomingDiff(diff));
        } else {
          // Process single incoming diff
          processIncomingDiff(data);
        }
      }
    });
  }

  const processIncomingDiff = (diff) => {
    // Process an incoming diff
    let [diffType, diffSeq, diffData, diffVisible] = diff;
    if (diffSeq === seq.current) {
      console.log(`Processing diff with seq ${seq.current}`);
      if (diffVisible) {
        layer.importJSON(diffData);
        setTangibleSeqs(existingSeqs => [...existingSeqs, seq.current]);
      }
      seq.current++;
    } else {
      console.log(`Expected diff with seq of ${seq.current} but got ${diffSeq}`);
    }
  };

  const transmitDiff = (diffType, data) => {
    if (!layerChannel) {
      return;
    }

    console.log(`Transmitting ${effect} diff with seq ${seq.current}...`);
    if (diffType === DiffType.Tangible) {
      // Store seq of tangible diff
      setTangibleSeqs(existingSeqs => [...existingSeqs, seq.current]);
      layerChannel.send({
        diff_type: diffType,
        seq: seq.current++,
        data: data.exportJSON(),
        visible: true
      });
    } else if (diffType === DiffType.Remove) {
      // Get seqs of removed diffs (these diffs still persist in layer.children until next reload)
      const removedDiffs = [];
      data.forEach((ind) => removedDiffs.push(tangibleSeqs[ind]));
      layerChannel.send({
        diff_type: diffType,
        seq: seq.current++,
        data: {'removed_diffs': removedDiffs}
      });
    } else if (diffType === DiffType.Translate) {
      // Get seqs of translated diffs and the updated item data (these diffs still persist in
      // layer.children until next reload)
      const translatedDiffs = [];
      data.forEach((ind) => translatedDiffs.push({
        seq: tangibleSeqs[ind],
        data: layer.children[ind].exportJSON()
      }));
      layerChannel.send({
        diff_type: diffType,
        seq: seq.current++,
        data: {'translated_diffs': translatedDiffs}
      });
    } else {
      console.log(`Invalid effect: ${diffType}`);
    }
  }

  useEffect(() => {
    // Set up action cable subscriber once layer is created
    if (!!layer) {
      setLayerChannel(setupSubscription());
    }
  }, [layer]);

  useEffect(() => {
    if (!!scope) {
      paperHandler();
    }
  }, [layerChannel]);

  useEffect(() => {
    // Transmit text diff if clicking out of a focused text box to change tool or color
    if (!!pathRef.current && pathRef.current instanceof Paper.PointText) {
      transmitDiff(DiffType.Tangible, pathRef.current);
      pathRef.current.fullySelected = false;
    }
    paperHandler();
  }, [activeTool, activeColor]);

  // useEffect(() => {
  //   if (!!scope) {
  //     pathRef.current = null;
  //     paperHandler();
  //   }
  // }, [pathState.length]);

  const eraseIntersectedItems = (path) => {
    // Handles item removal via eraser or deletion
    const removedItemIndices = [];
    layer.children.forEach((item, i) => {
      // Get index of removed items (layer.children has same order as tangibleSeqs)
      if (path.id !== item.id && path.intersects(item)) {
        item.visible = false;
        removedItemIndices.push(i);
      }
    });
    if (removedItemIndices.length > 0) {
      transmitDiff(DiffType.Remove, removedItemIndices);
    }
    path.remove();
    path = null;
  };

  const deleteSelectedItems = (path) => {
    const removedItemIndices = [];
    scope.project.selectedItems.forEach((selectedItem) => {
      let selectedItemIndex = layer.children.findIndex((item) => selectedItem.id === item.id);
      // Only remove items in current index
      if (selectedItemIndex >= 0) {
        removedItemIndices.push(selectedItemIndex);
      }
    });
    if (removedItemIndices.length > 0) {
      transmitDiff(DiffType.Remove, removedItemIndices);
    }
    path.remove();
    path = null;
  };

  const selectItemsInLasso = (path, rect) => {
    // Only select items in current layer
    layer.children.forEach((item) => {
      // Check if path or text (respectively) is in lasso
      if ((!!item.segments && item.segments.every((segment) => path.contains(segment.point))) ||
          (!!item.content && item.isInside(rect))) {
        item.fullySelected = true;
      }
    });
    path.remove();
    path = null;
  }

  const translateSelectedItems = (delta) => {
    const selectedItemIndices = [];
    scope.project.selectedItems.forEach((selectedItem) => {
      let selectedItemIndex = layer.children.findIndex((item) => selectedItem.id === item.id);
      // Only translate items in current layer
      if (selectedItemIndex >= 0) {
        selectedItemIndices.push(selectedItemIndex);
        selectedItem.translate(delta);
        selectedItem.fullySelected = false;
      }
    });
    if (selectedItemIndices.length > 0) {
      transmitDiff(DiffType.Translate, selectedItemIndices);
    }
  }

  const paperHandler = () => {
    let path = null;
    let rect = null;
    let p1 = null;
    let p2 = null;

    if (!scope) {
      return;
    }

    scope.view.onMouseDown = (event) => {
      scope.activate();
      // Transmit text diff if clicking out of a focused text box
      if (!!pathRef.current && pathRef.current instanceof Paper.PointText) {
        transmitDiff(DiffType.Tangible, pathRef.current);
        pathRef.current.fullySelected = false;
      }
      // Handle event according to active tool
      if (activeTool === CanvasTools.pen) {
        scope.project.deselectAll();
        pathRef.current = new Paper.Path();
      } else if (activeTool === CanvasTools.eraser) {
        scope.project.deselectAll();
        path = new Paper.Path();
      } else if (activeTool === CanvasTools.select) {
        p1 = new Paper.Point(event.point.x, event.point.y);
        if (rect && p1.isInside(rect) && scope.project.selectedItems.length > 0) {
          rect = null;
          path = null;
        } else {
          scope.project.deselectAll();
          rect = new Paper.Rectangle();
          path = new Paper.Path.Rectangle(rect);
        }
      } else if (activeTool === CanvasTools.text) {
        scope.project.deselectAll();
        const point = new Paper.Point(event.point.x, event.point.y);
        pathRef.current = new Paper.PointText({
          point: point,
          fontFamily: 'serif',
          fontSize: 25,
        });
        pathRef.current.fullySelected = true;
      }

      if (scope.project.selectedItems.length === 0) {
        if (activeTool === CanvasTools.eraser || activeTool === CanvasTools.select) {
          path.strokeColor = 'black';
          path.strokeWidth = 3;
          path.dashArray = [10, 12];
        } else {
          pathRef.current.strokeColor = activeColor;
          pathRef.current.strokeWidth = (activeTool === CanvasTools.pen) ? 3 : 1;
        }
      }
    };

    scope.view.onMouseDrag = (event) => {
      if (activeTool === CanvasTools.pen) {
        pathRef.current.add(event.point);
      } else if (activeTool === CanvasTools.eraser) {
        path.add(event.point);
      } else if (activeTool === CanvasTools.select) {
        p2 = new Paper.Point(event.point.x, event.point.y);
        if (scope.project.selectedItems.length === 0) {
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

    scope.view.onMouseUp = () => {
      if (activeTool === CanvasTools.pen) {
        pathRef.current.simplify(10);
        transmitDiff(DiffType.Tangible, pathRef.current);
        pathRef.current = null;
      } else if (activeTool === CanvasTools.eraser) {
        eraseIntersectedItems(path);
      } else if (activeTool === CanvasTools.select) {
        if (scope.project.selectedItems.length === 0) {
          selectItemsInLasso(path, rect);
        } else {
          translateSelectedItems(p2.subtract(p1));
        }
      }
    };

    scope.view.onKeyDown = (event) => {
      if (activeTool === CanvasTools.select && event.key === 'delete' && scope.project.selectedItems.length > 0) {
        deleteSelectedItems();
      } else if (activeTool === CanvasTools.text) {
        if (event.key === 'escape' || event.key === 'enter') {
          transmitDiff(DiffType.Tangible, pathRef.current);
          pathRef.current.fullySelected = false;
          pathRef.current = null;
        } else if (event.key === 'backspace') {
          path.content = pathRef.current.content.slice(0, -1);
        } else if (!!pathRef.current && event.character !== '') {
          pathRef.current.content += event.character;
        }
      }
    };
  };

  return null;
}
