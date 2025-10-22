# Pest Control Licensing System

A blockchain-based pest control licensing system for agriculture departments managing pesticide applicator licenses and usage reporting.

## Overview

Pest Control Licensing System provides a secure and transparent platform for agriculture departments to manage pesticide applicator licenses, track pesticide usage, and ensure safety compliance through blockchain technology.

## Real-Life Use Case

Agriculture departments license pesticide applicators for public safety and environmental protection. This system digitizes the licensing process, provides real-time usage tracking, and ensures compliance with safety regulations through immutable blockchain records.

## Features

### License Management
- Issue and renew pesticide applicator licenses
- Track license expiration dates and status
- Verify applicator credentials and certifications
- Manage different license types and categories
- Record training and continuing education

### Usage Tracking
- Record pesticide application events
- Track chemical types and quantities used
- Monitor application locations and dates
- Generate usage reports for compliance
- Alert for overuse or violations

### Safety Compliance
- Verify license validity before applications
- Track safety training completions
- Monitor violation history
- Enforce suspension and revocation
- Generate compliance reports

### Reporting & Analytics
- Generate usage statistics by region
- Track license renewal rates
- Monitor compliance trends
- Export regulatory reports
- Historical data analysis

## Smart Contract: pesticide-licensor

The `pesticide-licensor` contract manages all licensing and compliance operations with the following capabilities:

- **License Issuance**: Departments can issue new applicator licenses
- **Usage Recording**: Track pesticide application events
- **Compliance Tracking**: Monitor safety compliance and violations
- **License Management**: Handle renewals, suspensions, and revocations
- **Access Control**: Ensure only authorized departments can modify records

## Technical Stack

- **Blockchain**: Stacks blockchain
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Storage**: On-chain data storage for licenses and usage records

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/peterjame007/pest-control-licensing.git

# Navigate to project directory
cd pest-control-licensing

# Install dependencies
npm install
```

### Testing

```bash
# Check contract syntax
clarinet check

# Run tests
clarinet test
```

## Contract Functions

### Public Functions
- `issue-license`: Issue a new pesticide applicator license
- `renew-license`: Renew an existing license
- `suspend-license`: Suspend a license for violations
- `revoke-license`: Permanently revoke a license
- `record-application`: Record a pesticide application event
- `record-violation`: Record a safety violation

### Read-Only Functions
- `get-license`: Retrieve license details
- `is-license-valid`: Check if a license is currently valid
- `get-application-record`: Get pesticide application details
- `get-usage-stats`: Get usage statistics for a license
- `get-violation-history`: Get violation history for a license

## Security

- Only authorized agriculture department personnel can issue/modify licenses
- Immutable usage records prevent data tampering
- Automatic license expiration enforcement
- Secure violation tracking and enforcement

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## License

MIT License

## Contact

For questions or support, please open an issue in the repository.

## Acknowledgments

Built with Clarity on the Stacks blockchain, providing transparent and secure pesticide applicator licensing for public safety and environmental protection.
