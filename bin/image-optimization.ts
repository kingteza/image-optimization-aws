#!/usr/bin/env node
import 'source-map-support/register';
import { config } from 'dotenv';
import { resolve } from 'path';
import * as cdk from 'aws-cdk-lib';
import { ImageOptimizationStack } from '../lib/image-optimization-stack';

config({ path: resolve(__dirname, '../.env') });

const CDK_CONTEXT_FROM_ENV = [
  'S3_IMAGE_BUCKET_NAME',
  'STORE_TRANSFORMED_IMAGES',
  'S3_TRANSFORMED_IMAGE_EXPIRATION_DURATION',
  'S3_TRANSFORMED_IMAGE_CACHE_TTL',
  'CLOUDFRONT_ORIGIN_SHIELD_REGION',
  'CLOUDFRONT_CORS_ENABLED',
  'LAMBDA_MEMORY',
  'LAMBDA_TIMEOUT',
  'MAX_IMAGE_SIZE',
  'DEPLOY_SAMPLE_WEBSITE',
] as const;

const app = new cdk.App();
for (const key of CDK_CONTEXT_FROM_ENV) {
  const value = process.env[key];
  if (value !== undefined && value !== '') {
    app.node.setContext(key, value);
  }
}

new ImageOptimizationStack(app, 'ImgTransformationStack', {});

