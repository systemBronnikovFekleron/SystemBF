# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Платформа «Система Бронникова»** - информационная платформа с личным кабинетом и единой авторизацией для всех сервисов и сайтов системы Бронников-Феклерон.

Это образовательная экосистема для клиентов, учеников, специалистов и руководителей центров и клубов системы "Бронников-Феклерон".

## Current Repository State

Репозиторий в настоящее время содержит только документацию и спецификации:

- **AIDocs/Rails/** - Complete Rails 8 and Ruby documentation (20 files)
- **AIDocs/Концепция проекта** - Full project specification and requirements
- **.claude/skills/frontend-design/** - Frontend design skill for distinctive interfaces

## Technology Stack (Planned)

Based on the Rails documentation and project requirements:

- **Backend**: Ruby on Rails 8
- **Database**: PostgreSQL
- **Frontend**: Turbo + Stimulus (Rails 8 defaults)
- **Asset Pipeline**: Propshaft + Import Maps
- **Background Jobs**: Solid Queue (Rails 8 default)
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable / Action Cable
- **Authentication**: Custom or Devise (to be decided)
- **Authorization**: Pundit (recommended)

## Rails Documentation Structure

All Rails documentation is in Russian and follows a consistent structure:

1. **Ruby Basics** (01-09): Core Ruby language features, syntax, and best practices
2. **Rails Core** (10-16): Models, Controllers, Views, Routing, Migrations, Testing
3. **Advanced Topics** (17-20): Security, Performance, API, Turbo & Stimulus

### Key Documentation Files

- `01-ruby-basics.md` - Formatting, syntax, style guide
- `02-ruby-naming.md` - Naming conventions (snake_case, CamelCase, etc.)
- `10-rails-structure.md` - Rails 8 app structure and configuration
- `11-rails-models.md` - Active Record, validations, associations
- `17-rails-security.md` - Security best practices, CSRF, XSS, SQL injection
- `20-rails-turbo-stimulus.md` - Modern frontend with Turbo and Stimulus

## Key Architecture Requirements

From the project specification:

### User Roles & Classification
- Guests → Clients → Club Members → Representatives → Instructors → Specialists → Center Directors → Platform Admins

### Core Platform Features
1. **Единая авторизация (SSO)** - Single sign-on across all ecosystem services
2. **Личный кабинет** - User dashboard with profile, wallet, rating system
3. **Бизнес-аккаунт** - B2B space for partners and centers
4. **Маркетплейс** - Marketplace for centers and representatives with geolocation
5. **Витрина магазина** - Product/service storefront
6. **Календарь/Афиша** - Events calendar with booking and payment
7. **Внутренний счет (кошелек)** - User wallet for platform purchases
8. **Рейтинговая система** - User rating and bonus points system

### Integration Requirements
- WordPress sites integration (передача сессии авторизованного пользователя)
- CRM system integration
- Google Analytics
- Bizon365 (webinar system)
- Social networks (VK, FB, Twitter) sharing
- Payment processing

### Technical Requirements
- Mobile-responsive design
- Search functionality across all content
- Comment and discussion system
- Email notifications/newsletters management
- Content moderation (automated + manual)
- User privacy controls (152-ФЗ compliance)
- GDPR/Cookie consent

## Development Guidelines

When developing for this project, **always refer to the Rails documentation** in `AIDocs/Rails/`:

1. **Follow Rails 8 conventions** - Use new defaults (Solid Queue, Propshaft, etc.)
2. **Security first** - Always apply security best practices from `17-rails-security.md`
3. **Russian language** - All user-facing content and comments should be in Russian
4. **Performance** - Implement caching, pagination, N+1 prevention from start
5. **Testing** - Write RSpec tests for all features
6. **API Design** - Follow RESTful conventions and proper versioning
7. **Frontend** - Prefer Turbo Frames/Streams over heavy JavaScript

## Code Style

- **Ruby**: Follow conventions from `01-ruby-basics.md` and `02-ruby-naming.md`
- **Indentation**: 2 spaces (never tabs)
- **Line length**: 80-100 characters
- **String literals**: Add `# frozen_string_literal: true` to all Ruby files
- **Naming**: snake_case for methods/variables, CamelCase for classes
- **Database**: Use migrations for all schema changes, never edit schema.rb

## When Code Development Starts

This repository will eventually contain a Rails 8 application. When that happens:

### Expected Structure
```
app/
├── models/           # User, Profile, Event, Product, etc.
├── controllers/      # RESTful controllers + API namespace
├── views/           # ERB templates with Turbo integration
├── services/        # Business logic (payments, SSO, etc.)
├── policies/        # Pundit authorization policies
└── components/      # ViewComponents (optional)

config/
├── routes.rb        # Namespace: api, admin, user dashboard
├── database.yml     # PostgreSQL configuration
└── credentials/     # Encrypted secrets per environment

db/
├── migrate/         # All database migrations
└── seeds.rb         # Initial data (roles, etc.)
```

### Common Development Commands
(Will be added when Rails app is initialized)

## Notes

- This is a **greenfield project** - no legacy code to maintain
- Platform will serve Russian-speaking audience
- High emphasis on user experience and modern design (see frontend-design skill)
- Compliance with Russian data protection laws (152-ФЗ) is mandatory
