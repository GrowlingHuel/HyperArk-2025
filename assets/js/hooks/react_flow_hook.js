import { createRoot } from 'react-dom/client';
import React from 'react';
import LivingWebDiagram from '../components/LivingWebDiagram.jsx';

export default {
  mounted() {
    console.log('React Flow Hook mounted');
    
    // Get the container element
    const container = this.el;
    
    // Parse initial data from data attributes
    const nodesData = JSON.parse(container.dataset.nodes || '[]');
    const edgesData = JSON.parse(container.dataset.edges || '[]');
    
    console.log('Initial nodes:', nodesData);
    console.log('Initial edges:', edgesData);
    
    // Get the render target
    const renderTarget = container.querySelector('[data-phx-root]') || container;
    
    // Create root for React 18
    const root = createRoot(renderTarget);
    
    // Store the root for cleanup
    this.reactRoot = root;
    
    // Render the component
    const handleNodeDragEnd = (node) => {
      this.pushEvent('node_moved', {
        node_id: node.id,
        position_x: node.position.x,
        position_y: node.position.y
      });
    };
    
    const handleConnect = (params) => {
      this.pushEvent('connection_created', {
        source: params.source,
        target: params.target,
        source_handle: params.sourceHandle,
        target_handle: params.targetHandle
      });
    };
    
    const handleNodeDoubleClick = (node) => {
      this.pushEvent('node_double_click', { node_id: node.id });
    };
    
    const handleEdgesDelete = (deletedEdges) => {
      deletedEdges.forEach(edge => {
        this.pushEvent('connection_deleted', { edge_id: edge.id });
      });
    };
    
    root.render(
      React.createElement(LivingWebDiagram, {
        initialNodes: nodesData,
        initialEdges: edgesData,
        onNodeDragEnd: handleNodeDragEnd,
        onConnect: handleConnect,
        onNodeDoubleClick: handleNodeDoubleClick,
        onEdgesDelete: handleEdgesDelete
      })
    );
  },

  updated() {
    console.log('React Flow Hook updated');
    
    // Get updated data
    const nodesData = JSON.parse(this.el.dataset.nodes || '[]');
    const edgesData = JSON.parse(this.el.dataset.edges || '[]');
    
    // Re-render with updated data
    if (this.reactRoot) {
      const handleNodeDragEnd = (node) => {
        this.pushEvent('node_moved', {
          node_id: node.id,
          position_x: node.position.x,
          position_y: node.position.y
        });
      };
      
      const handleConnect = (params) => {
        this.pushEvent('connection_created', {
          source: params.source,
          target: params.target,
          source_handle: params.sourceHandle,
          target_handle: params.targetHandle
        });
      };
      
      const handleNodeDoubleClick = (node) => {
        this.pushEvent('node_double_click', { node_id: node.id });
      };
      
      const handleEdgesDelete = (deletedEdges) => {
        deletedEdges.forEach(edge => {
          this.pushEvent('connection_deleted', { edge_id: edge.id });
        });
      };
      
      this.reactRoot.render(
        React.createElement(LivingWebDiagram, {
          initialNodes: nodesData,
          initialEdges: edgesData,
          onNodeDragEnd: handleNodeDragEnd,
          onConnect: handleConnect,
          onNodeDoubleClick: handleNodeDoubleClick,
          onEdgesDelete: handleEdgesDelete
        })
      );
    }
  },

  destroyed() {
    console.log('React Flow Hook destroyed');
    // Cleanup is handled automatically by React 18's createRoot
    if (this.reactRoot) {
      this.reactRoot.unmount();
      this.reactRoot = null;
    }
  }
};
