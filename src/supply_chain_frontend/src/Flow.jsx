import React from 'react';
import ReactFlow, { Controls, Background } from 'reactflow';
import 'reactflow/dist/style.css';

// const nodes = [
//   {
//     id: '1',
//     data: { label: 'Hello1' },
//     position: { x: 0, y: 0 },
//   },
//   {
//     id: '2',
//     data: { label: 'Hello' },
//     position: { x: 100, y: 100 },
//   },
// ];
// const edges = [{ id: '1-2', source: '1', target: '2' }];
function Flow({nodes, edges}) {
  return (
    <div style={{ height: '300px' }}>
      <ReactFlow nodes={nodes} edges={edges}>
        <Background />
        <Controls />
      </ReactFlow>
    </div>
  );
}

export default Flow;