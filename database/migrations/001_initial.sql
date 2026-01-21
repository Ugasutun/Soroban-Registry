-- Create custom types
CREATE TYPE network_type AS ENUM ('mainnet', 'testnet', 'futurenet');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'failed');

-- Publishers table
CREATE TABLE publishers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stellar_address VARCHAR(56) NOT NULL UNIQUE,
    username VARCHAR(255),
    email VARCHAR(255),
    github_url VARCHAR(500),
    website VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_publishers_stellar_address ON publishers(stellar_address);

-- Contracts table
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id VARCHAR(56) NOT NULL,
    wasm_hash VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    publisher_id UUID NOT NULL REFERENCES publishers(id) ON DELETE CASCADE,
    network network_type NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    category VARCHAR(100),
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(contract_id, network)
);

CREATE INDEX idx_contracts_contract_id ON contracts(contract_id);
CREATE INDEX idx_contracts_publisher_id ON contracts(publisher_id);
CREATE INDEX idx_contracts_network ON contracts(network);
CREATE INDEX idx_contracts_is_verified ON contracts(is_verified);
CREATE INDEX idx_contracts_category ON contracts(category);
CREATE INDEX idx_contracts_name ON contracts(name);

-- Contract versions table
CREATE TABLE contract_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    wasm_hash VARCHAR(64) NOT NULL,
    source_url VARCHAR(500),
    commit_hash VARCHAR(40),
    release_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(contract_id, version)
);

CREATE INDEX idx_contract_versions_contract_id ON contract_versions(contract_id);

-- Verifications table
CREATE TABLE verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    status verification_status NOT NULL DEFAULT 'pending',
    source_code TEXT,
    build_params JSONB,
    compiler_version VARCHAR(50),
    verified_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verifications_contract_id ON verifications(contract_id);
CREATE INDEX idx_verifications_status ON verifications(status);

-- Contract interactions table (for statistics)
CREATE TABLE contract_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    user_address VARCHAR(56),
    interaction_type VARCHAR(50) NOT NULL,
    transaction_hash VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contract_interactions_contract_id ON contract_interactions(contract_id);
CREATE INDEX idx_contract_interactions_created_at ON contract_interactions(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON contracts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
