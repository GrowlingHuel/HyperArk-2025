import React, { useCallback } from 'react';
import ReactFlow, {
  Controls,
  Background,
  useNodesState,
  useEdgesState,
  addEdge
} from 'reactflow';

import ResourceNode from '../nodeTypes/ResourceNode.jsx';
import ProcessNode from '../nodeTypes/ProcessNode.jsx';
import SourceNode from '../nodeTypes/SourceNode.jsx';

// HyperCard greyscale color palette
const COLORS = {
  edgeActive: '#333333',
  edgePotential: '#999999',
  edgeSelected: '#000000',
};

const nodeTypes = {
  resource: ResourceNode,
  process: ProcessNode,
  source: SourceNode
};

function LivingWebDiagram({ 
  initialNodes, 
  initialEdges, 
  onNodeDragEnd, 
  onConnect: onConnectProp,
  onNodeDoubleClick: onNodeDoubleClickProp,
  onEdgesDelete: onEdgesDeleteProp 
}) {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // Handle node drag end - sync back to Phoenix
  const handleNodeDragEnd = useCallback((_event, node) => {
    if (onNodeDragEnd) {
      onNodeDragEnd(node);
    }
  }, [onNodeDragEnd]);

  // Handle connection creation
  const onConnect = useCallback((params) => {
    setEdges((eds) => addEdge(params, eds));
    if (onConnectProp) {
      onConnectProp(params);
    }
  }, [onConnectProp]);

  // Handle node double-click
  const handleNodeDoubleClick = useCallback((event, node) => {
    if (onNodeDoubleClickProp) {
      onNodeDoubleClickProp(node);
    }
  }, [onNodeDoubleClickProp]);

  // Handle edge deletion
  const handleEdgesDelete = useCallback((edgesToDelete) => {
    setEdges((eds) => eds.filter(edge => !edgesToDelete.includes(edge)));
    if (onEdgesDeleteProp) {
      onEdgesDeleteProp(edgesToDelete);
    }
  }, [onEdgesDeleteProp, setEdges]);

  return (
    <div style={{ width: '100%', height: '100%', background: '#FFF' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeDragEnd={handleNodeDragEnd}
        onConnect={onConnect}
        onNodeDoubleClick={handleNodeDoubleClick}
        onEdgesDelete={handleEdgesDelete}
        nodeTypes={nodeTypes}
        fitView
        connectionLineStyle={{ stroke: COLORS.edgeActive, strokeWidth: 2 }}
        defaultEdgeOptions={{
          style: { stroke: COLORS.edgeActive, strokeWidth: 2 },
          type: 'default',
          animated: false
        }}
      >
        <Controls />
        <Background color="#CCC" gap={16} />
      </ReactFlow>
    </div>
  );
}

export default LivingWebDiagram;

