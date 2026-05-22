# coding-playbook
A comprehensive guide on how I think programs should be coded nowadays.

## Introduction

I write this playbook to establish all my continues learning about coding in my adventure to look for simplicity first.

The main and final goal of this playbook is to provide the building blocks that will allow any engineer working in high level, general purpose languages like C# and Java, to produce code that is as simple as possible, as honest as possible and as robust as possible.

## Scope

The target is the kind of code that makes up ordinary business software: line-of-business systems, web and desktop applications, internal services, integration code.

It is **not** aimed at real-time, low-latency, or high-throughput workloads. Those obey different constraints (cache locality, memory layout, lock-free structures) and the building blocks here will not always be the right tool for them.

For now it will be a collection of markdown files with principles, examples, justifications and decisions.

## Code examples

Examples in this playbook use the current LTS versions of each target language:

- **C# 14** on **.NET 10 LTS** (released November 2025)
- **Java 25 LTS** (released September 2025)