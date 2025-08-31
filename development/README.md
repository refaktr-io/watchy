# Development Resources

This directory contains development tools, documentation, and resources for contributors to the Watchy Cloud platform.

## 📁 **Directory Structure**

- **`docs/`** - Development documentation
  - `DEPLOYMENT.md` - Platform deployment guide
  - `CONTRIBUTING.md` - Contribution guidelines  
  - `AWS_PROFILE_SETUP.md` - AWS configuration
  - `GITHUB_ACTIONS_OPTIMIZATION.md` - CI/CD details

- **`tests/`** - Testing framework and test files

## 🔧 **Development Workflow**

### **Platform Development**
1. Work in `platform/` directory for infrastructure changes
2. Use GitHub Actions for automated deployment
3. Test changes in development environment first

### **Customer Template Development**  
1. Modify templates in `customer-templates/templates/`
2. Update customer documentation in `customer-templates/docs/`
3. Test customer deployment scenarios

### **CI/CD Pipeline**
- **GitHub Actions** handles all deployments
- **Smart change detection** only deploys what changed
- **Optimized for speed** - most changes deploy in under 5 minutes

## 📋 **Getting Started**

1. Read `docs/CONTRIBUTING.md` for contribution guidelines
2. Set up AWS credentials per `docs/AWS_PROFILE_SETUP.md`  
3. Review `docs/DEPLOYMENT.md` for deployment process
4. Check `docs/GITHUB_ACTIONS_OPTIMIZATION.md` for CI/CD details

## 🧪 **Testing**

Use the `tests/` directory for:
- Unit tests for monitor code
- Integration tests for deployments
- Customer scenario testing
