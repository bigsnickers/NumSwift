
#include "include/numswiftc.h"
#include "time.h"

extern void nsc_flatten2d(NSC_Size input_size,
                          float *const *input,
                          float *result) {
  
  int length = input_size.rows * input_size.columns;
  float *padded = malloc(length * sizeof(float));
  
  for (int i = 0; i < input_size.rows * input_size.columns; i++) {
    padded[i] = 0;
  }

  for (int r = 0; r < input_size.rows; r++) {
    for (int c = 0; c < input_size.columns; c++) {
      float value = input[r][c];
      padded[(input_size.columns * r) + c] = value;
    }
  }
  
  memcpy(result, padded, length * sizeof(float));
  free(padded);
}

double scaled_cosine(const double i) {
  return 0.5f * (1.0f - cos(i * M_PI));
}

double randfrom(const double min, const double max) {
  double range = (max - min);
  double div = RAND_MAX / range;
  return min + (rand() / div);
}

extern void random_array(const int size, double *result) {
  double *perlin = malloc(size * sizeof(double));
  
  srand( (unsigned)time( NULL ) );

  for (int i = 0; i < size + 1; i++) {
    double random = randfrom(0.0f, 1000.0f) / 1000.0f;
    perlin[i] = random;
  }
  
  memcpy(result, perlin, size * sizeof(double));
  free(perlin);
}

extern double nsc_perlin_noise(const double x,
                               const double y,
                               const double z,
                               const double amplitude,
                               const int octaves,
                               const int size,
                               const double* perlin_seed) {

  const int yWrapB = 4;
  const int yWrap = 1 << yWrapB;
  const int zWrapB = 8;
  const int zWrap = 1 << zWrapB;
  
  double mutable_x = x;
  double mutable_y = y;
  double mutable_z = z;
  
  if (x < 0.0f) {
    mutable_x = -x;
  }
  if (y < 0.0f) {
    mutable_y = -y;
  }
  if (z < 0.0f) {
    mutable_z = -z;
  }
  
  int xi = (int)floor(mutable_x);
  int yi = (int)floor(mutable_y);
  int zi = (int)floor(mutable_z);

  double xf = mutable_x - (double)(xi);
  double yf = mutable_y - (double)(yi);
  double zf = mutable_y - (double)(zi);
  
  double rxf = 0.0f;
  double ryf = 0.0f;
  
  double r = 0.0f;
  double ampl = 0.5;
  
  double n1 = 0.0f;
  double n2 = 0.0f;
  double n3 = 0.0f;
  
  for (int i = 0; i < octaves; i++) {
    int of = xi + (yi << yWrapB) + (zi << zWrapB);
    
    rxf = scaled_cosine(xf);
    ryf = scaled_cosine(yf);
    
    n1 = perlin_seed[of & size];
    n1 += rxf * (perlin_seed[(of + 1) & size] - 1);
    n2 = perlin_seed[(of + yWrap) & size];
    n2 += rxf * (perlin_seed[(of + yWrap + 1) & size] - n2);
    n1 += ryf * (n2 - n1);
    
    of += zWrap;
    n2 = perlin_seed[of & size];
    n2 += rxf * (perlin_seed[(of + 1) & size] - n2);
    n3 = perlin_seed[(of + yWrap) & size];
    n3 += rxf * (perlin_seed[(of + yWrap + 1) & size] - n3);
    n2 += ryf * (n3 - n2);
    
    n1 += scaled_cosine(zf) * (n2 - n1);

    r += n1 * ampl;
    ampl *= amplitude;
    xi <<= 1;
    xf *= 2;
    yi <<= 1;
    yf *= 2;
    zi <<= 1;
    zf *= 2;
    
    if (xf >= 1.0f) {
      xi += 1;
      xf -= 1;
    }
    
    if (yf >= 1.0f) {
      yi += 1;
      yf -= 1;
    }
    
    if (zf >= 1.0f) {
      zi += 1;
      zf -= 1;
    }
  }
  
  return r;
}

extern void nsc_stride_pad(const float input[],
                           float *result,
                           NSC_Size input_size,
                           NSC_Size stride_size) {
  
  int numToPadRows = stride_size.rows - 1;
  int numToPadCols = stride_size.columns - 1;
  
  int newRows = input_size.rows + ((stride_size.rows - 1) * (input_size.rows - 1));
  int newColumns = input_size.columns + ((stride_size.columns - 1) * (input_size.columns - 1));

  int length = newRows * newColumns;
  float *padded = malloc(length * sizeof(float));
  
  for (int i = 0; i < newRows * newColumns; i++) {
    padded[i] = 0;
  }
  
  int i = 0;

  if (numToPadCols > 0 && numToPadRows > 0) {
    
    for (int r = 0; r < newRows; r += stride_size.rows) {
      for (int c = 0; c < newColumns; c += stride_size.columns) {
        int index = (r * newRows) + c;
        padded[index] = input[i];
        i += 1;
      }
    }
  }
  
  memcpy(result, padded, length * sizeof(float));
  free(padded);
}

extern void nsc_padding_calculation(NSC_Size stride,
                                    NSC_Padding padding,
                                    NSC_Size filter_size,
                                    NSC_Size input_size,
                                    int *paddingTop,
                                    int *paddingBottom,
                                    int *paddingLeft,
                                    int *paddingRight) {
  
  int inputRows = input_size.rows;
  int inputColumns = input_size.columns;
  
  int strideR = stride.rows;
  int strideC = stride.columns;
  
  int filterRows = filter_size.rows;
  int filterColumns = filter_size.columns;
  
  if (padding == 1) {
    double height = (double)inputRows;
    double width = (double)inputColumns;
    
    double outHeight = ceil(height / (double)strideR);
    double outWidth = ceil(width / (double)strideC);
    
    double padAlongHeight = fmax((outHeight - 1) * (double)strideR + (double)filterRows - height, 0);
    double padAlongWidth = fmax((outWidth - 1) * (double)strideC + (double)filterColumns- width, 0);
    
    int paddingT = (int)floor(padAlongHeight / 2);
    int paddingB = (int)padAlongHeight - (double)paddingT;
    int paddingL = (int)floor(padAlongWidth / 2);
    int paddingR = (int)padAlongWidth - (double)paddingL;
    
    *paddingTop = paddingT;
    *paddingBottom = paddingB;
    *paddingLeft = paddingL;
    *paddingRight = paddingR;
    
    return;
  } else {
    
    *paddingTop = 0;
    *paddingBottom = 0;
    *paddingLeft = 0;
    *paddingRight = 0;
    return;
  }
}

extern void nsc_specific_zero_pad(const float input[],
                                  float *result,
                                  NSC_Size input_size,
                                  int paddingTop,
                                  int paddingBottom,
                                  int paddingLeft,
                                  int paddingRight) {
  
  int inputRows = input_size.rows;
  int inputColumns = input_size.columns;
  
  int padded_row_total = inputRows + paddingLeft + paddingRight;
  int padded_col_total = inputColumns + paddingTop + paddingBottom;
  
  int length = padded_row_total * padded_col_total;
  float *padded = malloc(length * sizeof(float));
  
  for (int i = 0; i < padded_row_total * padded_col_total; i++) {
    padded[i] = 0;
  }
  
  if (padded == NULL || input == NULL)
    return;
  
  for (int r = 0; r < inputRows; r++) {
    for (int c = 0; c < inputColumns; c++) {
      int padded_c = c + paddingLeft;
      int padded_r = r + paddingTop;
      
      int index = (padded_r  * padded_row_total) + padded_c;
      padded[index] = input[(r * inputRows) + c];
    }
  }
    
  memcpy(result, padded, length * sizeof(float));
  
  free(padded);
}

extern void nsc_zero_pad(const float input[],
                         float *result,
                         NSC_Size filter_size,
                         NSC_Size input_size,
                         NSC_Size stride) {
  int paddingLeft;
  int paddingRight;
  int paddingBottom;
  int paddingTop;
  
  int *pad_l_ptr = &paddingLeft;
  int *pad_r_ptr = &paddingRight;
  int *pad_b_ptr = &paddingBottom;
  int *pad_t_ptr = &paddingTop;
  
  nsc_padding_calculation(stride,
                          same,
                          filter_size,
                          input_size,
                          pad_t_ptr,
                          pad_b_ptr,
                          pad_l_ptr,
                          pad_r_ptr);
  
  int inputRows = input_size.rows;
  int inputColumns = input_size.columns;
  
  int padded_row_total = inputRows + paddingLeft + paddingRight;
  int padded_col_total = inputColumns + paddingTop + paddingBottom;
  
  int length = padded_row_total * padded_col_total;
  float *padded = malloc(length * sizeof(float));
  
  for (int i = 0; i < padded_row_total * padded_col_total; i++) {
    padded[i] = 0;
  }
  
  if (padded == NULL || input == NULL)
    return;
  
  for (int r = 0; r < inputRows; r++) {
    for (int c = 0; c < inputColumns; c++) {
      int padded_c = c + paddingLeft;
      int padded_r = r + paddingTop;
      
      int index = (padded_r  * padded_row_total) + padded_c;
      padded[index] = input[(r * inputRows) + c];
    }
  }
    
  memcpy(result, padded, length * sizeof(float));
  
  free(padded);
}

extern void nsc_conv2d(const float signal[],
                       const float filter[],
                       float *result,
                       NSC_Size stride,
                       NSC_Padding padding,
                       NSC_Size filter_size,
                       NSC_Size input_size) {
  int paddingLeft;
  int paddingRight;
  int paddingBottom;
  int paddingTop;
  
  int *pad_l_ptr = &paddingLeft;
  int *pad_r_ptr = &paddingRight;
  int *pad_b_ptr = &paddingBottom;
  int *pad_t_ptr = &paddingTop;
  
  nsc_padding_calculation(stride,
                          padding,
                          filter_size,
                          input_size,
                          pad_t_ptr,
                          pad_b_ptr,
                          pad_l_ptr,
                          pad_r_ptr);
  
  int padded_row_total = input_size.rows + paddingLeft + paddingRight;
  int padded_col_total = input_size.columns + paddingTop + paddingBottom;
  
  float working_signal[padded_row_total * padded_col_total];// = malloc(padded_row_total * padded_col_total * sizeof(float));
  if (padding == same) {
    nsc_zero_pad(signal,
                 working_signal,
                 filter_size,
                 input_size,
                 stride);
  }
  
  int inputRows = input_size.rows;
  int inputColumns = input_size.columns;
  
  int strideR = stride.rows;
  int strideC = stride.columns;
  
  int filterRows = filter_size.rows;
  int filterColumns = filter_size.columns;
  
  if (result == NULL)
    return;
  
  int rf = filterRows;
  int cf = filterColumns;
  int rd = inputRows + paddingTop + paddingBottom; //havnt dealt with padding yet
  int cd = inputColumns + paddingLeft + paddingRight;
  
  int max_r = rd - rf + 1;
  int max_c = cd - cf + 1;

  int expected_r = ((inputRows - filterRows + paddingTop + paddingBottom) / strideR) + 1;
  int expected_c = ((inputColumns - filterColumns + paddingLeft + paddingRight) / strideC) + 1;

  float mutable_result[expected_r * expected_c]; //= malloc(expected_r * expected_c * sizeof(float));

  for (int i = 0; i < expected_r * expected_c; i++) {
    mutable_result[i] = 0.0f;
  }

  int result_index = 0;
  for (int r = 0; r < max_r; r += strideR) {
    for (int c = 0; c < max_c; c += strideC) {
      float sum = 0;
      
      for (int fr = 0; fr < filterRows; fr++) {
        
        for (int fc = 0; fc < filterColumns; fc++) {
          int current_data_row = r + fr;
          int current_data_col = c + fc;
          
          int signal_index = (current_data_row * cd) + current_data_col;
          int filter_index = (fr * cf) + fc;
          
          float s_data = padding == valid ? signal[signal_index] : working_signal[signal_index]; //do some checking of size here?
          float f_data = filter[filter_index]; //do some checking of size here?
          sum += s_data * f_data;
        }
      }
      
      mutable_result[result_index] = sum;
      result_index += 1;
    }
  }
  
  memcpy(result, mutable_result, expected_r * expected_c * sizeof(float));
}

extern void nsc_transConv2d(const float signal[],
                            const float filter[],
                            float *result,
                            NSC_Size stride,
                            NSC_Padding padding,
                            NSC_Size filter_size,
                            NSC_Size input_size) {
  
  int inputRows = input_size.rows;
  int inputColumns = input_size.columns;
  
  int strideR = stride.rows;
  int strideC = stride.columns;
  
  int filterRows = filter_size.rows;
  int filterColumns = filter_size.columns;
  
  int rows = (inputRows - 1) * strideR + filterRows;
  int columns = (inputColumns - 1) * strideC + filterColumns;
  
  int length = rows * columns;
  
  float working_result[length];
  
  for (int i = 0; i < length; i++) {
    working_result[i] = 0.0f;
  }

  if (result == NULL)
    return;
  
  for (int i = 0; i < inputRows; i++) {
    int i_prime = i * strideR;
    
    for (int j = 0; j < inputColumns; j++) {
      int j_prime = j * strideC;
      
      for (int r = 0; r < filterRows; r++) {
        for (int c = 0; c < filterColumns; c++) {
          int result_index = ((r + i_prime) * rows) + (c + j_prime);
          int signal_index = (i * inputRows) + j;
          int filter_index = (r * filterRows) + c;
          
          working_result[result_index] += signal[signal_index] * filter[filter_index];
        }
      }
  
    }
  }
  
  int pad_left = 0;
  int pad_right = 0;
  int pad_top = 0;
  int pad_bottom = 0;
  
  if (padding == same) {
    pad_left = (int)floor(((double)filterRows - (double)strideR) / (double)2);
    pad_right = filterRows - strideR - pad_left;
    pad_top = (int)floor(((double)filterColumns - (double)strideC) / (double)2);
    pad_bottom = filterColumns - strideC - pad_top;
  }
  
  int padded_row_total = rows - (pad_bottom + pad_top);
  int padded_col_total = columns - (pad_left + pad_right);
  
  float padded[padded_col_total * padded_row_total];
  
  for (int i = 0; i < padded_col_total * padded_row_total; i++) {
    padded[i] = 0.0f;
  }
  
  int padded_index = 0;
  for (int r = pad_top; r < rows - pad_bottom; r++) {
    for (int c = pad_left; c < columns - pad_right; c++) {
      int index = (r  * rows) + c;
      float w_r = working_result[index];
      padded[padded_index] = w_r;
      padded_index++;
    }
  }

  memcpy(result, padded, padded_col_total * padded_row_total * sizeof(float));
}
