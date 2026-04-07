import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const templateContent = readFileSync(resolve('template.yaml'), 'utf-8');

describe('CloudFormation template', () => {
  const requiredResources = [
    'DynamoDBTable',
    'LambdaRole',
    'LambdaFunction',
    'RestApi',
    'ProxyResource',
    'ProxyMethod',
    'OptionsMethod',
    'Deployment',
    'Stage',
    'ApiKey',
    'UsagePlan',
    'UsagePlanKey',
    'LambdaPermission',
  ];

  it.each(requiredResources)('has resource: %s', (resource) => {
    const pattern = new RegExp(`^  ${resource}:`, 'm');
    expect(templateContent).toMatch(pattern);
  });

  it('has StageName parameter', () => {
    expect(templateContent).toMatch(/^\s+StageName:/m);
  });

  it('has ProjectName parameter', () => {
    expect(templateContent).toMatch(/^\s+ProjectName:/m);
  });

  it('has ApiInvokeUrl output', () => {
    expect(templateContent).toMatch(/^\s+ApiInvokeUrl:/m);
  });

  it('has ApiKeyValue output', () => {
    expect(templateContent).toMatch(/^\s+ApiKeyValue:/m);
  });
});
