# Green Man Tavern: In-House RAG System Implementation Plan

## 📋 Executive Summary
Build a complete knowledge-aware agent system without MindsDB dependency. Estimated timeline: **5-7 days**.

## 🎯 System Architecture

```
User Question → Agent Router → Semantic Search → Enhanced Prompt → OpenAI API → Response
                    ↓
              PDF Knowledge Base
                    ↓
            Vector Embeddings (PgVector)
```

## ⏱️ Implementation Timeline

### Day 1: PDF Processing Pipeline (8 hours)
**Objective:** Convert PDFs to searchable text chunks

```elixir
# Core Modules to Build:
- PDFTextExtractor (using pdftotext)
- TextChunker (semantic chunking)
- ContentNormalizer (clean & structure)
```

**Tasks:**
1. Set up PDF text extraction with fallbacks
2. Implement semantic chunking (1000 chars with 200 overlap)
3. Create chunk metadata system (source, page ranges, etc.)
4. Build batch processing for 45 PDFs

### Day 2: Vector Database Setup (6 hours)
**Objective:** Store and search document embeddings

```elixir
# Core Modules:
- PgVector Migration & Setup
- EmbeddingStorage
- VectorOperations
```

**Tasks:**
1. Install and configure PgVector extension
2. Create embeddings table schema
3. Set up vector indexing for fast search
4. Build basic CRUD operations

### Day 3: Embeddings Pipeline (6 hours)
**Objective:** Generate and manage text embeddings

```elixir
# Core Modules:
- OpenAIEmbedder
- EmbeddingBatchProcessor  
- EmbeddingCache
```

**Tasks:**
1. Integrate OpenAI embeddings API
2. Build batch processing with rate limiting
3. Implement embedding caching to reduce costs
4. Create embedding update strategies

### Day 4: Semantic Search Engine (6 hours)
**Objective:** Find relevant knowledge for queries

```elixir
# Core Modules:
- SemanticSearch
- RelevanceScorer
- ResultRanker
```

**Tasks:**
1. Implement cosine similarity search
2. Build hybrid search (vector + keyword)
3. Create relevance scoring system
4. Add result deduplication and ranking

### Day 5: Agent Integration (8 hours)
**Objective:** Connect knowledge to AI agents

```elixir
# Core Modules:
- KnowledgeEnhancedAgent
- PromptEnhancer
- ContextManager
```

**Tasks:**
1. Modify existing agents to use knowledge context
2. Build dynamic prompt enhancement
3. Implement context window management
4. Create fallback mechanisms

## 💾 Database Schema

```sql
-- PgVector enabled table
CREATE TABLE document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    embedding VECTOR(1536),  -- OpenAI embedding dimension
    metadata JSONB,
    document_id UUID,
    chunk_index INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast similarity search
CREATE INDEX ON document_chunks USING ivfflat (embedding vector_cosine_ops);
```

## 🔧 Technical Stack

**Already Have:**
- Elixir/Phoenix
- PostgreSQL
- OpenAI API access

**To Add:**
- PgVector extension
- Custom RAG pipeline
- Vector search algorithms

## 💰 Cost Projections

**Initial Setup:**
- Embedding 45 PDFs: ~$2-5 (one-time)
- **Monthly:** < $1 for query embeddings

**vs MindsDB:**
- No hidden costs
- Predictable pricing
- Full cost control

## 🚀 Deployment Strategy

**Phase 1** (Days 1-2): PDF processing standalone
**Phase 2** (Days 3-4): Vector search standalone  
**Phase 3** (Day 5): Integrated agent system
**Phase 4** (Future): Web scraping integration

## 📊 Success Metrics

- **Query Response Time:** < 2 seconds
- **Relevance Accuracy:** > 80% human-rated
- **Cost per Query:** < $0.001
- **Knowledge Coverage:** All 45 PDFs searchable

## 🛠️ Risk Mitigation

1. **PDF Extraction Failure:** Fallback to command-line tools
2. **OpenAI API Limits:** Implement exponential backoff
3. **Vector Search Performance:** PgVector indexing optimization
4. **Context Window Limits:** Smart chunk selection

## 🎯 Final Deliverables

1. Complete PDF-to-knowledge pipeline
2. Vector search API
3. Knowledge-enhanced agents
4. Admin interface for managing documents
5. Monitoring and analytics

## 📈 Long-term Advantages

- **Full Control:** No black-box dependencies
- **Extensible:** Easy to add web content, images, other docs
- **Debuggable:** Every step transparent and monitorable
- **Cost Effective:** Pay only for actual API usage
- **Portable:** Can migrate between cloud providers easily

---

**Context Window Used:** ~15% of 128K context
**Plan Format:** Downloadable reference document for future chats
**Next Step:** Begin Day 1 implementation with PDF processing pipeline

This plan gives you a production-ready knowledge system without MindsDB overhead, full control over your data, and predictable costs. Ready to start Day 1?

**Save this file as:** `green_man_tavern_rag_implementation_plan.md`
