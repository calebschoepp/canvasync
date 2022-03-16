import { useEffect, useRef, useState } from 'react'
import Paper from 'paper';
import { CanvasTools } from './notebook';
import consumer from '../channels/consumer';

// TODO: make font size, line width, etc. variables

const DiffType = {
  Tangible: 'tangible',
  Remove: 'remove',
  Translate: 'translate',
  FetchExisting: 'fetch-existing'
}

export function Layer({ scope, layer, layerId, activeTool, activeColor }) {
  const seqRef = useRef(0);
  const tangibleSeqsRef = useRef([]);
  const pathRef = useRef(null);
  const [outOfSync, setOutOfSync] = useState(false);
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
        if (data['diff_type'] === DiffType.FetchExisting) {
          if (seqRef.current === 0) {
            // Load existing diffs (only want to allow this to be handled when next sequence number to accept is 0),
            // additionally do not check each diffs sequence number (we are only loading visible tangible diffs here)
            data['data'].forEach((diff) => processIncomingDiff(diff, false));
            // Update next expected seq number
            seqRef.current = data['next_seq'];
          }
        } else {
          // Process single incoming diff
          processIncomingDiff(data, true);
        }

        // Maintain layer hierarchy after adding a diff to the owner layer (paperJS will perform some behind the
        // scenes optimizations and merge the two layers if not)
        if (!scope) {
          layer.sendToBack();
        }
      }
    });
  }

  const processIncomingDiff = (diff, checkSeq) => {
    // Process an incoming diff
    const diffType = diff['diff_type'];
    const diffSeq = diff['seq'];

    if (diffType !== DiffType.Tangible && diffType !== DiffType.Remove && diffType !== DiffType.Translate) {
      console.log(`Invalid diff type ${diffType}`);
      return;
    }

    if (diffSeq < seqRef.current) {
      console.log(`Diff already part of notebook state`);
      return;
    }

    if (checkSeq && diffSeq > seqRef.current) {
      console.log(`Out of order diff (expected seq = ${seqRef.current} but got seq = ${diffSeq})`);
      setOutOfSync(true);
      return;
    }

    if (diffType === DiffType.Tangible) {
      if (diff['visible']) {
        // Import tangible diff and mark as not selected (for some reason paperJS auto selects these imported items)
        layer.importJSON(diff['data']).fullySelected = false;
        if (checkSeq) {
          tangibleSeqsRef.current.push(seqRef.current);
        } else {
          tangibleSeqsRef.current.push(diffSeq);
        }
      }
    } else if (diffType === DiffType.Remove) {
      const removedDiffs = diff['data']['removed_diffs'].sort((a, b) => a - b);
      const removedIndices = []
      removedDiffs.forEach((removedSeq) => {
        // If removed items are drawn then get their indices (layer.children has same order as tangibleSeqsRef)
        let i = tangibleSeqsRef.current.findIndex((seq) => removedSeq === seq);
        if (i >= 0) {
          removedIndices.push(i);
        }
      });
      // Remove items at indices from layer
      removedIndices.sort((a, b) => b - a);
      removedIndices.forEach((i) => {
        layer.children[i].remove();
        tangibleSeqsRef.current.splice(i, 1);
      });
    } else if (diffType === DiffType.Translate) {
      const translatedDiffs = diff['data']['translated_diffs'];
      const delta = new Paper.Point(diff['data']['delta_x'], diff['data']['delta_y']);
      translatedDiffs.forEach((diff) => {
        let i = tangibleSeqsRef.current.findIndex((seq) => diff['seq'] === seq);
        // If translated items are drawn then translate them (layer.children has same order as tangibleSeqsRef)
        if (i >= 0) {
          layer.children[i].translate(delta);
        }
      });
    }

    // Increment seqRef
    seqRef.current++;
  };

  useEffect(() => {
    if (outOfSync) {
      refreshLayer();
      setOutOfSync(false);
    }
  }, [outOfSync]);

  const refreshLayer = () => {
    // Reset layer state and re-fetch existing layer diffs
    console.log('Refreshing layer');
    seqRef.current = 0;
    tangibleSeqsRef.current = [];
    pathRef.current = null;
    layer.removeChildren();
    // Refetch data
    transmitDiff(DiffType.FetchExisting, null);
  };

  const transmitDiff = (diffType, data) => {
    console.log(`Sending ${diffType} diff${(diffType !== DiffType.FetchExisting) ? 
        ` (seq = ${seqRef.current})` : ''}...`);
    if (diffType === DiffType.FetchExisting) {
      layerChannel.send({'diff_type': DiffType.FetchExisting});
    } else if (diffType === DiffType.Tangible) {
      // Store seq of tangible diff
      tangibleSeqsRef.current.push(seqRef.current);
      layerChannel.send({
        'diff_type': diffType,
        'seq': seqRef.current++,
        'data': data.exportJSON(),
        'visible': true
      });
    } else if (diffType === DiffType.Remove) {
      // Get seqs of removed diffs (these diffs still persist in layer.children until next reload)
      layerChannel.send({
        'diff_type': diffType,
        'seq': seqRef.current++,
        'data': {'removed_diffs': data}
      });
    } else if (diffType === DiffType.Translate) {
      // Get seqs of translated diffs and the updated item data (these diffs still persist in
      // layer.children until next reload)
      const translatedDiffs = [];
      data.indices.forEach((ind) => translatedDiffs.push({
        'seq': tangibleSeqsRef.current[ind],
        'data': layer.children[ind].exportJSON()
      }));
      layerChannel.send({
        'diff_type': diffType,
        'seq': seqRef.current++,
        'data': {'translated_diffs': translatedDiffs, 'delta_x': data.delta_x, 'delta_y': data.delta_y}
      });
    }
  }

  useEffect(() => {
    // Set up action cable subscriber once layer is created
    if (!!layer) {
      setLayerChannel(setupSubscription());
    }
  }, [layer]);

  useEffect(() => {
    // Once layer is channel is set up, call paperHandler (only do this for owner layer if owner or participant
    // layer if participant)
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

  const eraseIntersectedItems = (path) => {
    // Handles item removal via eraser
    const indicesToRemove = [];
    const removedSeqs = [];
    layer.children.forEach((item, i) => {
      // Get index and sequence number of removed items (layer.children has same order as tangibleSeqsRef)
      if (path.id !== item.id && path.intersects(item)) {
        removedSeqs.push(tangibleSeqsRef.current[i]);
        indicesToRemove.push(i);
      }
    });
    // Remove erased items
    path.remove();
    indicesToRemove.sort((a, b) => b - a);
    indicesToRemove.forEach((i) => {
      layer.children[i].remove();
      tangibleSeqsRef.current.splice(i, 1);
    });
    // Create remove diff if any items were erased
    if (removedSeqs.length > 0) {
      transmitDiff(DiffType.Remove, removedSeqs);
    }
  };

  const deleteSelectedItems = () => {
    // Handles item removal via select and delete
    const indicesToRemove = [];
    const removedSeqs = [];
    scope.project.selectedItems.forEach((selectedItem) => {
      // Get index and sequence number of removed items (layer.children has same order as tangibleSeqsRef)
      let i = layer.children.findIndex((item) => selectedItem.id === item.id);
      if (i >= 0) {
        indicesToRemove.push(i);
        removedSeqs.push(tangibleSeqsRef.current[i]);
      }
    });
    // Remove selected items
    indicesToRemove.sort((a, b) => b - a);
    indicesToRemove.forEach((i) => {
      layer.children[i].remove();
      tangibleSeqsRef.current.splice(i, 1);
    });
    // Create remove diff if any items were deleted
    if (removedSeqs.length > 0) {
      transmitDiff(DiffType.Remove, removedSeqs);
    }
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
  }

  const translateSelectedItems = (delta) => {
    const translatedIndices = [];
    scope.project.selectedItems.forEach((selectedItem) => {
      let selectedItemIndex = layer.children.findIndex((item) => selectedItem.id === item.id);
      // Only translate items in current layer
      if (selectedItemIndex >= 0) {
        translatedIndices.push(selectedItemIndex);
        selectedItem.translate(delta);
        selectedItem.fullySelected = false;
      }
    });
    if (translatedIndices.length > 0) {
      transmitDiff(DiffType.Translate, {indices: translatedIndices, delta_x: delta.x, delta_y: delta.y});
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
        path = null;
      } else if (activeTool === CanvasTools.select) {
        if (scope.project.selectedItems.length === 0) {
          selectItemsInLasso(path, rect);
          path = null;
        } else {
          translateSelectedItems(p2.subtract(p1));
          path = null;
        }
      }
    };

    scope.view.onKeyDown = (event) => {
      if (activeTool === CanvasTools.select && scope.project.selectedItems.length > 0 &&
          (event.key === 'delete' || event.key === 'backspace')) {
        deleteSelectedItems();
        path = null;
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
